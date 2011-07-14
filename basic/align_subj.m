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
defaults.precision = 0;
params = propval(varargin, defaults);

warning('off', 'eeg_toolbox:pulsealign:WindowOverlap')
for sess=subj.sess
  % read the eegfile(s) from the sess structure
  if ~isfield(sess, 'eegfile')
    error('Each session must have an "eegfile" field.')
  end
  eegfiles = sess.eegfile;
  if ~iscell(eegfiles)
    eegfiles = {eegfiles};
  end

  % get the events structure
  eventfile = fullfile(sess.dir, params.eventfile);
  if ~exist(eventfile, 'file')
    error('Events file not found: %s\n', eventfile)
  end
  
  % there should be only one behavioral sync pulse file
  behsyncfile = fullfile(sess.dir, 'eeg.eeglog.up');
  if ~exist(behsyncfile, 'file')
    % if we haven't already, extract the UP pulses
    raw_behsyncfile = fullfile(sess.dir, 'eeg.eeglog');
    if ~exist(raw_behsyncfile,'file')
      error('Behavioral pulse file not found: %s\n', raw_behsyncfile)
    end
    fixEEGLog(raw_behsyncfile, behsyncfile);
  end
  
  % get the samplerate
  samplerate = GetRateAndFormat(fileparts(eegfiles{1}));
  
  % for runAlign, make eegfile point to a specific channel
  for i = 1:length(eegfiles)
    eegfiles{i} = [eegfiles{i} '.001'];
  end
  
  good_align = false;
  flip = 1;
  flipped = 0;
  auto_mark = false;
  auto_mark_thresh = 100;
  limit = 25;
  flip_limit = 90;
  while ~good_align
    if auto_mark
      for i = 1:length(eegfiles)
        [pathstr, basename] = fileparts(eegfiles{i});
        fileroot = fullfile(subj.dir, params.pulse_dir, basename);
        eegsyncfiles{i} = mark_sync_pulses(fileroot, sync_channels{i}, flip, ...
                                           auto_mark_thresh);
      end
      
    else
      % get EEG sync files
      eegsyncfiles = cell(1, length(eegfiles));
      sync_channels = cell(1, length(eegfiles));
      for i = 1:length(eegfiles)
        [pathstr, basename] = fileparts(eegfiles{i});

        % get the EEG sync pulse file
        pulse_path = fullfile(subj.dir, params.pulse_dir, ...
                              [basename params.pulse_ext]);
        temp = dir(pulse_path);
        if length(temp) == 0
          warning('No EEG sync pulse files found that match: %s', pulse_path);
          return
        elseif length(temp) > 1
          fprintf('Multiple EEG sync pulse files found that match: %s\n', ...
                  pulse_path)
          % use the first one that matches this pattern: '###.sync.txt'
          for j = 1:length(temp)
            if length(temp) > 1
              if ~isempty(regexp(temp(j).name,'\w*\d\d\d.sync.txt'))
                temp = temp(j);
                fprintf('Using: %s\n', temp.name);
              end
            end
          end
          if length(temp) > 1
            error('No valid sync files found.');
          end
        end
        eegsyncfiles{i} = fullfile(subj.dir, params.pulse_dir, temp.name);
      end
      
      % extract the sync channels used for manual pulse marking from the
      % sync pulse filename
      c = regexp(eegsyncfiles{i}, '\.', 'split');
      c2 = cellfun(@str2num, c, 'UniformOutput', false);
      sync_channels{i} = [c2{~cellfun(@isempty, c2)}];
    end

    % run the alignment
    bad_align = false;
    lastwarn('')
    try
      runAlign(samplerate, {behsyncfile}, eegsyncfiles, eegfiles, ...
               {eventfile}, 'mstime', 0, 0, params.precision);
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
      
    if bad_align
      auto_mark = true;
      auto_mark_thresh = auto_mark_thresh * .95;
      if auto_mark_thresh < flip_limit && flipped < 2
        fprintf('Retrying with sync channel flipped...\n')
        flip = ~flip;
        flipped = flipped + 1;
        auto_mark_thresh = 100;
      end
      
      if auto_mark_thresh < limit
        if flip == 1
          fprintf('Hit absolute limit. Retrying with sync channel flipped...\n')
          flip = 0;
          auto_mark_thresh = 100;
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

