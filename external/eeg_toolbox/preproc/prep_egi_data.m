function prep_egi_data(subject, sess_dir, varargin)
%PREP_EGI_DATA   Process one session of a pyEPL experiment with EGI recordings.
%
%  Makes some assumptions based on standard PyEPL directory structure,
%  but many of the default directories may be modified using params (see
%  below). If steps_to_run is set, only specified preprocessing steps
%  will be run; otherwise, an automated system will attempt to determine
%  which steps must be run for the session. In general, a given step
%  will be run if the output files from that step do not exist or if the
%  input files for that step have been modified recently (e.g. if the
%  events structure has been modified in the past 24 hours, alignment
%  will be rerun).
%
%  prep_egi_data(subject, sess_dir, ...)
%
%  INPUTS:
%   subject:  subject identifier string.
%
%  sess_dir:  path to the directory containing data for the session.
%
%  PARAMS:
%  These options can be modified using parameter, value pairs passes as
%  additional inputs. All paths can be absolute or relative to sess_dir.
%  Defaults are shown in parentheses.
%   steps_to_run - specifies which parts of post-processing to run. 
%                  Cell array which may contain: 'split', 'reref',
%                  and/or 'align'. ({})
%   agethresh    - if steps_to_run is empty, each step will be
%                  run if relevant files have been modified in the
%                  last [agethresh] days. (.8)
%   eventfiles   - cell array of paths to .mat files containing
%                  events structures. ({'events.mat'})
%   pulsedir     - path (relative to sess_dir) containing behavioral
%                  sync pulses. ('')
%   rawfiles     - cell array of paths to .raw files. May contain
%                  wildcards. ('*.raw*')
%   badchanfiles - cell array with paths to .txt files with one channel 
%                  number per row, indicating which channels were "bad"
%                  in this session. ({'bad_chan.txt'})
%   norerefdir   - specifies where split, but not rereferenced, EEG
%                  files should be saved. ('eeg/eeg.noreref')
%   rerefdir     - specifies where rereferenced EEG files should be
%                  saved. ('eeg/eeg.reref')
%   eog          - cell array where each cell contains a pair of channel
%                  numbers. Indicates the pairs that will be used to
%                  find eye artifacts. ({[25 127], [8 126]})
%   channels     - vector of channel numbers indicating which channels
%                  should be included in rereferencing. (1:129)
%   ziprawfile   - logical; if true, the raw file is bzipped after
%                  splitting. (false)
%   runclean     - logical; if true, unixclean will be run. (false)
%   unixclean    - UNIX command to be run after rereferencing to
%                  delete or move unneeded files. Default: deletes
%                  all channel files in eeg/eeg.noreref

% input checks
if ~exist('subject', 'var') || ~ischar(subject)
  error('You must pass a subject identifier.')
elseif ~exist('sess_dir', 'var') || ~ischar(sess_dir)
  error('You must give the path to a session directory.')
elseif ~exist(sess_dir, 'dir')
  error('Session directory does not exist: %s', sess_dir)
end

% set up directory structure
eegdir = fullfile(sess_dir, 'eeg');

% process additional inputs
def.eventfiles = {'events.mat'};
def.pulsedir = '';
def.rawfiles = {'*.raw*'};
def.badchanfiles = {'bad_chan.txt'};
def.norerefdir = fullfile(eegdir, 'eeg.noreref');
def.rerefdir = fullfile(eegdir, 'eeg.reref');
def.eog = {[25 127], [8 126]};
def.blink_thresh = 100;
def.channels = 1:129;
def.steps_to_run = {};
def.only_run = {};
def.agethresh = .8;
def.ziprawfile = false;
def.runclean = false;
def.unixclean = ['rm ' fullfile(def.norerefdir, '*.[0-9][0-9][0-9]')];

[eid,emsg,eventfiles,pulsedir,rawfiles,badchanfiles,norerefdir,rerefdir,eog,blink_thresh,channels,steps_to_run,only_run,agethresh,ziprawfile,runclean,unixclean] = getargs(fieldnames(def),struct2cell(def),varargin{:});

% not a cell? make it a cell
if ~iscell(badchanfiles)
  badchanfiles = {badchanfiles};
end
if ~iscell(rawfiles)
  rawfiles = {rawfiles};
end
if ~iscell(steps_to_run)
  steps_to_run = {steps_to_run};
end

% fix paths that are given relative to the EEG directory
for i=1:length(rawfiles)
  rawfiles{i} = fullfile(eegdir, rawfiles{i});
end
for i=1:length(badchanfiles)
  badchanfiles{i} = fullfile(eegdir, badchanfiles{i});
end

cd(sess_dir);

% check what has been done
try
  get_eeg_files(norerefdir);
  done.split = true;
catch
  done.split = false;
end
try
  get_eeg_files(rerefdir);
  done.reref = true;
catch
  done.reref = false;
end

steps = {'split', 'reref', 'align'};
if ~isempty(steps_to_run)
  for i = 1:length(steps)
    modified.(steps{i}) = ismember(steps{i}, steps_to_run);
  end
else
  % check which steps have sources that have been recently modified
  modified.split = filecheck(rawfiles, agethresh);
  modified.reref = filecheck(badchanfiles, agethresh);
  modified.align = false;
  mod_events = filecheck(eventfiles, agethresh);
  if mod_events
    % make sure this isn't just because we recently aligned events;
    % check the time on the backup that gets saved by logalign
    backup_times = [];
    for i=1:length(eventfiles)
      d = dir([eventfiles{i} '.old']);
      backup_times = [backup_times d.datenum];
    end
    if isempty(backup_times) || filecheck(eventfiles, -0.001, max(backup_times))
      modified.align = true;
    end
  end
end

% add up what's been done and what needs to be redone to make a plan
run = get_steps(done, modified);
if ~isempty(only_run)
  for i = 1:length(steps)
    if ~ismember(steps{i}, only_run)
      run.(steps{i}) = false;
    end
  end
end

% split EEG data into channels
if run.split
  for i=1:length(rawfiles)
    [pathstr, name, ext] = fileparts(rawfiles{i});
    temp = get_eeg_files(pathstr, name, ext);
    
    for j=1:length(temp)
      rawfile = temp{j};

      % unzip if necessary
      fixed = strrep(rawfile, ' ', '\ ');
      if strcmp(rawfile(end-3:end), '.bz2')
        unix(['bunzip2 -v ' fixed]);
        [pathstr, name] = fileparts(rawfile);
        rawfile = fullfile(pathstr, name);
        [pathstr, name] = fileparts(fixed);
        fixed = fullfile(pathstr, name);
        ziprawfile = 1; % we want to re-zip after splitting             
      end

    try
      % split this .raw file
      egi_split(rawfile, subject, norerefdir);
    catch err
      % if we errored out, re-zip the raw file
      if ziprawfile
        % zip
        unix(['bzip2 -v ' fixed]);
      end
      rethrow(err)
    end

    if ziprawfile
      % zip
      unix(['bzip2 -v ' fixed]);
    end
    
    end
  end
end

% rereferencing
if run.reref
  badchan = [];
  for i = 1:length(badchanfiles)
    try
      % read the bad channel file if it exists; concatenate all bad
      % channels into one set
      c = read_chans_file(badchanfiles{i});
      badchan = cat(1, badchan, c);
    catch
      % continue without excluding bad channels from this file from
      % rereferencing
      fprintf('Warning: unable to read bad channel file ''%s''. Skipping.\n', ...
              badchanfiles{i});
    end
  end
  
  % rereference using "good" channels to calculate average
  fileroots = get_eeg_files(norerefdir);
  for i=1:length(fileroots)
    reref(fileroots{i}, {channels}, setdiff(channels, badchan), rerefdir);
  end
  
  % save out all bad channels (possibly none) to new file in reref directory
  write_chans_file(fullfile(rerefdir, 'bad_chan.txt'), badchan);
  
  % if specified, run clean script
  if runclean
    unix(unixclean);
  end
end

% alignment and artifact detection
if run.align
  % align
  fprintf('Aligning...\n', sess_dir)
  samplerate = GetRateAndFormat(norerefdir);
  beh_sync_dir = fullfile(sess_dir, pulsedir);
  align_egi(rerefdir, norerefdir, samplerate, beh_sync_dir, eventfiles);
    
  % add artifact info
  fprintf('Finding blink artifacts...\n')
  for i = 1:length(eventfiles)
    addArtifacts(eventfiles{i}, eog, blink_thresh, 0);
  end
end


function run = get_steps(done, modified)
  run = struct('split', false, 'reref', false, 'align', false);
  
  if modified.split || (modified.reref && ~done.split) ...
                    || (modified.align && ~done.reref && ~done.split)
    run.split = 1;
  end
  if modified.split || modified.reref || (modified.align && ~done.reref)
    run.reref = 1;
  end
  if modified.split || modified.align
    run.align = 1;
  end
%endfunction

function align_egi(eeg_dir, eeg_sync_dir, samplerate, beh_sync_dir, eventfiles)
  %ALIGN_EGI   Align EGI data to behavioral pyEPL data.
  %
  %  align_egi(eeg_dir, eeg_sync_dir, samplerate, beh_dir, eventfiles)
  %
  %  INPUTS:
  %       eeg_dir:  path to the directory containing EEG channel files
  %                 to be aligned.
  %
  %  eeg_sync_dir:  path to the directory containing DIN files
  %                 corresponding to each individual .raw file.
  %
  %    samplerate:  samplerate of the EEG data (assumed to be the same
  %                 for all of this session's .raw files)
  %
  %  beh_sync_dir:  directory containing behavioral sync pulses, in
  %                 either:
  %                  'eeg.eeglog'
  %                  'eeg.eeglog.up'
  %
  %    eventfiles:  cell array of paths to events structures. Default:
  %                  [beh_sync_dir]/events.mat
  
  % input checks
  if ~exist('eeg_dir', 'var') || ~ischar(eeg_dir)
    error(['You must give the path to the directory contatining EEG ' ...
           'data to be aligned.'])
  elseif ~exist('eeg_sync_dir', 'var') || ~ischar(eeg_sync_dir)
    error(['You must give the path to the directory contatining EEG ' ...
           'sync pulses.'])
  elseif ~exist('samplerate', 'var') || ~isnumeric(samplerate)
    error('You must provide a samplerate.')
  elseif ~exist('beh_sync_dir', 'var') || ~ischar(beh_sync_dir)
    error(['You must give the path to the directory contatining ' ...
          'behavioral sync pulses.'])
  end
  if ~exist('eventfiles', 'var')
    eventfiles = {fullfile(beh_dir, 'events.mat')};
  end
  
  % get the EEG files
  fileroots = get_eeg_files(eeg_dir);
  
  eegsyncfiles = cell(1, length(fileroots));
  eegfiles = cell(1, length(fileroots));
  for i=1:length(fileroots)
    % EEG sync pulse files
    [pathstr, basename] = fileparts(fileroots{i});
    try
      sync_files = get_eeg_files(eeg_sync_dir, basename, '.D*');
    catch
      error('eeg_toolbox:prep_egi_data:PulseFileNotFound', ...
            'Pulse file not found: %s.', ...
            fullfile(eeg_sync_dir, [basename '.D*']));
    end
    
    % event code corresponding to sync pulses seems to depend on the
    % individual setup. Since sync pulses happen about once a second,
    % will probably be more of them than other event codes; so, we'll
    % assume that the channel with the most events contains sync pulses.
    % This assumption may be wrong and, if so, would result in failed
    % alignment.
    n_events = NaN(1, length(sync_files));
    for j = 1:length(sync_files)
      fid = fopen(sync_files{j});
      n_events(j) = nnz(fread(fid, inf, 'int8'));
      fclose(fid);
    end
    [y, max_ind] = max(n_events);
    eegsyncfiles(i) = sync_files(max_ind);
    
    % channels files
    eegfiles{i} = [fileroots{i} '.001'];
  end

  % behavioral sync pulse file
  behsyncfile = fullfile(beh_sync_dir, 'eeg.eeglog.up');
  if ~exist(behsyncfile,'file')
    % if we haven't already, extract the UP pulses
    fixEEGLog(fullfile(beh_sync_dir, 'eeg.eeglog'), behsyncfile);
  end
  
  % set parameters
  time_field = 'mstime';
  isfrei = false;
  isegi = true;

  % align
  runAlign(samplerate, {behsyncfile}, eegsyncfiles, eegfiles, ...
           eventfiles, time_field, isfrei, isegi);
%endfunction

function files = get_eeg_files(eegdir, basename, ext)
  %GET_EEG_FILES   Find EEG files.
  %
  %  files = get_eeg_files(eegdir, basename, ext)
  %
  %  Returns a cell array of paths to files that match the
  %  criteria. If an extension is specified, the returned
  %  filenames will include the file extension; otherwise,
  %  the extension will be omitted.
  
  %input checks
  if ~exist('eegdir', 'var') || ~ischar(eegdir)
    error('You must give the path to a directory.')
  elseif ~exist(eegdir, 'dir')
    error('Directory does not exist: %s', eegdir)
  end
  if ~exist('basename', 'var')
    basename = '*';
  end
  if ~exist('ext', 'var')
    ext = '.001';
    clip_ext = true;
  else
    clip_ext = false;
  end
  
  file = {};
  
  % search
  pattern = fullfile(eegdir, [basename ext]);
  d = dir(pattern);
  if isempty(d)
    error('no files found that match: %s', pattern)
  end
  
  % get the complete paths
  for i=1:length(d)
    if clip_ext
      [pathstr, name] = fileparts(d(i).name);
      files{i} = fullfile(eegdir, name);
    else
      files{i} = fullfile(eegdir, d(i).name);
    end
  end
%endfunction

function update = filecheck(files, agethresh, time)
  %FILECHECK   See if any files have been recently modified.
  %
  %  update = filecheck(files, agethresh, time)
  %
  %  INPUTS:
  %       files:  cell array of files to check.
  %
  %   agethresh:  time (in days) before start_time to check 
  %               for changes.
  %
  %  start_time:  time in datenum form. Default is now.
  %
  %  OUTPUTS:
  %      update:  boolean indicating whether any of the
  %               files have changed.

  % input checks
  if ~exist('files', 'var') || ~iscell(files) || isempty(files)
    error('You must pass a cell array of paths to files.')
  end
  if ~exist('agethresh', 'var')
    agethresh = 1; % one day
  end
  if ~exist('time', 'var')
    time = now;
  end
  
  update = false;
  for i=1:length(files)
    % search for files that match this pattern
    d = dir(files{i});
    if length(d)==0
      return
    end
    
    % get the time since the most recent update; if time is not
    % now, age may be negative
    age = time - max([d.datenum]);
    if age < agethresh
      update = 1;
      return
    end
  end
%endfunction
