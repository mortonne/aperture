function subj = align_subj(subj, varargin)
%ALIGN_SUBJ   Align a subject's events to EEG data.
%
%  subj = align_subj(subj, ...)
%
%  INPUTS:
%    subj:  a subject structure, where each sess subfield has the
%           following fields:
%            dir     - directory where behavioral data is stored
%            eegfile - path to the EEG files, including the filename,
%                      without the .XXX suffix that indicates the
%                      channel
%
%  OUTPUTS:
%     subj:  the subject structure, unmodified. This is only output for
%            purposes of compatibility with apply_to_subj.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   eventfile - path (relative to each sess.dir) to the events
%               structure. ('events.mat')
%   pulse_ext - file extension for the pulse files, to be appended to
%               the EEG fileroot for each session. May contain wildcards
%               (*). ('*.sync.txt')
%   pulse_dir - directory where pulse files are stored, relative to
%               subj.dir. ('eeg.noreref')
%   precision - precision of alignment method. May be:
%                0 - older method, which uses start and end windows and
%                    interpolates
%                1 - newer method that uses all pulses. (default)
%
%  EXAMPLE:
%   % path to directory with behavioral data
%   clear subj
%   subj.sess.dir = '/data/eeg/TJ003/behavioral/iCatFR/session_0';
%
%   % path to an EEG channel file, minus the .XXX extension
%   subj.sess.eegfile = '/data/eeg/TJ003/eeg.reref/TJ003_18Feb09_1335';
%   pulse_dir = '/data/eeg/TJ003/eeg.noreref';
%
%   % load [subj.sess.dir]/events.mat, align, add eegoffset and eegfile
%   % fields, and resave
%   align_subj(subj, 'pulse_dir', pulse_dir);
%
%  NOTES:
%   This script makes various assumptions about directory structure.
%   Each sess.dir must contain:
%    eeg.eeglog.up OR eeg.eeglog
%
%   The directory containing each EEG file must contain a file called
%   params.txt which has information about samplerate.
%
%   There must be a EEG channel file [sess.eegfile].001 for each
%   session.

% input checks
if ~exist('subj', 'var')
  error('You must pass a subject structure.')
end

% options
defaults.eventfile = 'events.mat';
defaults.pulse_ext = '*.sync.txt';
defaults.pulse_dir = 'eeg.noreref';
defaults.precision = 1;
params = propval(varargin, defaults);

warning('off', 'eeg_toolbox:pulsealign:WindowOverlap')
for i = 1:length(subj.sess)
  % get information about sync files
  sync = get_sync_info(subj, i, params);
  
  % settings for auto alignment
  good_align = false;
  auto_mark = false;
  %stat = 'clip';
  stat = 'local_max';
  flip = 1;
  flipped = 0;
  flip_limit = 80; % high threshold before switching direction first
  %auto_mark_thresh = 100; % percentile threshold for including peaks
  auto_mark_thresh = 100;
  limit = 1; % minimum percentile to use before giving up
  prev_n_pulses = zeros(1, sync.n_files);
  
  while ~good_align
    bad_align = false;
    run_this_align = true;
    
    if auto_mark
      % attempt to detect pulses in the sync channels
      n_pulses = NaN(1, sync.n_files);
      eegsyncfiles = cell(1, sync.n_files);
      for i = 1:sync.n_files
        % get the EEG files in the pulse directory
        [pathstr, basename] = fileparts(sync.eeg_files{i});
        fileroot = fullfile(subj.dir, params.pulse_dir, basename);
        
        % find pulses in the EEG file that should contain the syncs
        [eegsyncfiles{i}, pulses] = ...
            mark_sync_pulses(fileroot, sync.channels{i}, flip, ...
                             stat, auto_mark_thresh);
        n_pulses(i) = length(pulses);
      end
      
      % if the same number of pulses were found as before, don't
      % bother testing alignment again
      if all(n_pulses == prev_n_pulses)
        run_this_align = false;
        bad_align = true;
      end
      prev_n_pulses = n_pulses;
      
    else
      % there are already hand-marked sync pulses; attempt to use
      % these first, then try auto-detection if alignment fails
      try
        eegsyncfiles = get_sync_files(subj, sync, params);
      catch err
        % couldn't find any manual sync files. skip to running
        % autoalign
        run_this_align = false;
        bad_align = true;
      end
    end

    % run the alignment
    if run_this_align
      bad_align = false;
      lastwarn('')
      try
        % attempt to find a match between behavioral and EEG sync pulses
        runAlign(sync.samplerate, {sync.beh_sync_file}, ...
                 eegsyncfiles, sync.eeg_chan_files, ...
                 {sync.event_file}, 'mstime', 0, 0, params.precision);
      catch err
        bad_align = true;
        fprintf('runAlign threw an error.\n')
        %getReport(err)
      end
      
      w = lastwarn;
      if strcmp(strtrim(w), 'The start and end windows overlap.')
        fprintf('Pulse range too small.\n')
        bad_align = true;
      end
    end
      
    if bad_align
      % if alignment failed, set to run auto align next time
      if auto_mark
        % decrease the percentile threshold, to let in more
        % candidate spikes
        auto_mark_thresh = auto_mark_thresh * .95;
      end
      auto_mark = true;
      
      if auto_mark_thresh < flip_limit && flipped < 2
        fprintf('Retrying with sync channel flipped...\n')
        flip = ~flip;
        flipped = flipped + 1;
        auto_mark_thresh = 100;
        prev_n_pulses = zeros(1, sync.n_files);
      end
      
      if auto_mark_thresh < limit
        if flip == 1
          fprintf('Hit absolute limit. Retrying with sync channel flipped...\n')
          flip = 0;
          auto_mark_thresh = 100;
          prev_n_pulses = zeros(1, sync.n_files);
        else
          error('Auto sync pulse marking has failed.')
        end
      end
    else
      fprintf('Alignment successful.\n\n')
      good_align = true;
    end
  end
end
warning('on', 'eeg_toolbox:pulsealign:WindowOverlap')


function sync = get_sync_info(subj, sess_no, params)

sess = subj.sess(sess_no);

% read the eegfile(s) from the sess structure
if ~isfield(sess, 'eegfile')
  error('Each session must have an "eegfile" field.')
end

% EEG fileroots
eegfiles = sess.eegfile;
if ~iscell(eegfiles)
  eegfiles = {eegfiles};
end
n_files = length(eegfiles);

% channel(s) containing sync pulses
sync_channels = sess.sync;
if ~iscell(sync_channels)
  sync_channels = {sync_channels};
end

% events structure
eventfile = fullfile(sess.dir, params.eventfile);
if ~exist(eventfile, 'file')
  error('Events file not found: %s\n', eventfile)
end

% there should be only one behavioral sync pulse file
behsyncfile = get_pyepl_syncfile(sess.dir);

% get the samplerate
samplerate = GetRateAndFormat(fileparts(eegfiles{1}));

% for runAlign, make eegfile point to a specific channel
eegchanfiles = eegfiles;
for i = 1:n_files
  eegchanfiles{i} = [eegfiles{i} '.001'];
end

% place the various pieces of info into the structure
sync.n_files = length(eegfiles);
sync.eeg_files = eegfiles;
sync.channels = sync_channels;
sync.event_file = eventfile;
sync.beh_sync_file = behsyncfile;
sync.samplerate = samplerate;
sync.eeg_chan_files = eegchanfiles;


function sync_files = get_sync_files(subj, sync, params)

sync_files = cell(1, sync.n_files);
for i = 1:sync.n_files
  % find the EEG sync pulse file; should be in the same directory
  % as the EEG files
  [pathstr, basename] = fileparts(sync.eeg_files{i});
  
  % search for the pulse file, using the designated ext
  pulse_path = fullfile(subj.dir, params.pulse_dir, ...
                        [basename params.pulse_ext]);
  d = dir(pulse_path);
  
  if length(d) == 0
    error('No EEG sync pulse files found that match: %s', pulse_path);
  elseif length(d) > 1
    fprintf('Multiple EEG sync pulse files found that match: %s\n', ...
            pulse_path)
    % use the first one that matches this pattern: '###.sync.txt'
    for j = 1:length(d)
      if length(d) > 1
        if ~isempty(regexp(d(j).name,'\w*\d\d\d.sync.txt'))
          d = d(j);
          fprintf('Using: %s\n', d.name);
        end
      end
    end
    if length(d) > 1
      error('No valid sync files found.');
    end
  end
  sync_files{i} = fullfile(subj.dir, params.pulse_dir, d.name);
end


