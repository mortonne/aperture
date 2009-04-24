function align_subj(subj, params)
%ALIGN_SUBJ   Align a subject's events to EEG data.
%
%  align_subj(subj, params)
%
%  INPUTS:
%    subj:  a subject structure, where each sess subfield has the
%           following fields:
%            dir     - directory where behavioral data is stored
%            eegfile - path to the EEG files, including the filename,
%                      without the .XXX suffix that indicates the channel
%
%  params:  structure specifying options for running the alignment. See
%           below.
%
%  PARAMS:
%   eventfile - path (relative to each sess.dir) to the events structure.
%               Default: 'events.mat'
%   pulse_ext - file extension for the pulse files, to be appended to
%               the EEG fileroot for each session. May contain wildcards (*).
%               Default: '*.sync.txt'
%   pulse_dir - directory where pulse files are stored. Default is the
%               parent directory of the first session's EEG file
%
%  EXAMPLE:
%   % path to directory with behavioral data
%   clear subj params
%   subj.sess.dir = '/data/eeg/TJ003/behavioral/iCatFR/session_0';
%
%   % path to an EEG channel file, minus the .XXX extension
%   subj.sess.eegfile = '/data/eeg/TJ003/eeg.reref/TJ003_18Feb09_1335';
%
%   % change from the default pulse_dir
%   params.pulse_dir = '/data/eeg/TJ003/eeg.noreref';
%
%   % load [subj.sess.dir]/events.mat, align, add eegoffset and eegfile
%   % fields, and resave
%   align_subj(subj, params);
%
%  NOTES:
%   This script makes various assumptions about directory structure. Each
%   sess.dir must contain:
%    eeg.eeglog.up OR eeg.eeglog
%
%   The directory containing each EEG file must contain a file called
%   params.txt which has information about samplerate.
%
%   There must be a EEG channel file [sess.eegfile].001 for each session.   

% input checks
if ~exist('subj','var')
  error('You must pass a subject structure.')
end
if ~exist('params','var')
  params = [];
end

params = structDefaults(params, ...
                        'eventfile', 'events.mat', ...
                        'pulse_ext', '*.sync.txt', ...
                        'pulse_dir', fileparts(subj.sess(1).eegfile));

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
  if ~exist(eventfile,'file')
    error('Events file not found: %s\n', eventfile)
  end
  
  % get sync files
  eegsyncfiles = cell(1,length(eegfiles));
  for i=1:length(eegfiles)
    [pathstr,basename] = fileparts(eegfiles{i});

    % get the EEG sync pulse file
    pulse_path = fullfile(params.pulse_dir, [basename params.pulse_ext]);
    temp = dir(pulse_path);
    if length(temp)==0
      error('No EEG sync pulse files found that match: %s', pulse_path)
      elseif length(temp)>1
      error('Multiple EEG sync pulse files found that match: %s', pulse_path)
    end
    eegsyncfiles{i} = fullfile(params.pulse_dir, temp.name);

    % for runAlign, make eegfile point to a specific channel
    eegfiles{i} = [eegfiles{i} '.001'];
  end

  % there should be only one behavioral sync pulse file
  behsyncfile = fullfile(sess.dir,'eeg.eeglog.up');
  if ~exist(behsyncfile,'file')
    % if we haven't already, extract the UP pulses
    raw_behsyncfile = fullfile(sess.dir, 'eeg.eeglog');
    if ~exist(raw_behsyncfile,'file')
      error('Behavioral pulse file not found: %s\n', raw_behsyncfile)
    end
    fixEEGLog(raw_behsyncfile, behsyncfile);
  end
  
  % get the samplerate
  samplerate = GetRateAndFormat(fileparts(eegfiles{1}));
  
  % run the alignment
  runAlign(samplerate,{behsyncfile},eegsyncfiles,eegfiles,{eventfile},'mstime',0,0);
end
