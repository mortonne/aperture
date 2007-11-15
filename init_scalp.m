function eeg = init_scalp(dataroot, resDir, sessions, experiment, elecLocsFile)
%
%INIT_SCALP - after post-processing of all subjects, running this
%script prepares a scalp EEG experiment for analysis
%
% FUNCTION: eeg = init_scalp(dataroot, resDir, sessions, experiment, elecLocsFile)
% INPUT: dataroot - directory containing subject folders
%        resDir - directory in which to save eeg results
%        sessions - filename of m-file that outputs a 'subj'
%                   struct, or the subj struct itself (see README).
%        experiment - name of the experiment (optional)
%        elecLocsFile - text file containing a list of electrode numbers
%        and their corresponding regions (optional)
%
% OUTPUT: eeg, a struct containing all basic info for this experiment;
% gets passed into all other eeg analysis scripts
%
% EXAMPLE:
% dataroot = '/data/eeg/scalp/catFR';
% resDir = '/users/morton/EXPERIMENTS/catFR/results';
% sessions = 'iCatFR_sessions.m';
%            or a subj struct: subj(1).id = subj_00; subj.sess(1).eventsFile = '/data/eeg/scalp/catFR/subj_00/session_0/events.mat'
% experiment = 'catFR';
% elecLocsFile = '~/eeg/GSN200-128chanlocs.txt';
%

% set minimum defaults
if ~exist('elecLocsFile', 'var')
  elecLocsFile = '';
end
if ~exist('experiment', 'var')
  expriment = 'unknown';
end

if ~exist(resDir)
  mkdir(resDir);
end  

% create the eeg struct
eeg = struct('experiment', experiment, 'recordingType', 'scalp', 'dataroot', dataroot, 'resDir', resDir);

% add eventsFile info for each subj, session
if isstr(sessions)
  run(sessions);
  eeg.subj = subj;
elseif isstruct(sessions)
  eeg.subj = sessions;
end

% if an electrode locations file is available, read it
if ~isempty(elecLocsFile)
  [channels regions] = textread(elecLocsFile, '%d%s'); 
  
  for c=1:length(channels)
    chan(c).number = channels(c);
    chan(c).region = regions{c};
  end
else
  channels = 1:129;
  
  for c=1:length(channels)
    chan(c).number = channels(c);
    chan(c).region = '';
  end
end

for s=1:length(eeg.subj)
  
  % each subject gets the same channel info
  eeg.subj(s).chan = chan;
  
  % for each session, find out which channels were good
  for n=1:length(eeg.subj(s).sess)
    bad_chan_dir = fullfile(fileparts(eeg.subj(s).sess(n).eventsFile), 'eeg');
    temp = dir(fullfile(bad_chan_dir, '*.bad_chan'));
    bad_chans = textread(fullfile(bad_chan_dir, temp.name));
    eeg.subj(s).sess(n).goodChans = setdiff(channels, bad_chans);
  end
end

save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');


