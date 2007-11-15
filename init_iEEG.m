function eeg = init_iEEG(dataroot, resDir, sessions, experiment)
%
%INIT_IEEG - after post-processing of all subjects, running this
%script prepares an intracranial EEG experiment for analysis
%
% FUNCTION: eeg = init_iEEG(dataroot, resDir, sessions, experiment)
%
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
% dataroot = '/data/eeg';
% resDir = '/users/morton/EXPERIMENTS/iCatFR/results';
% sessions = 'iCatFR_sessions.m';
%            or subj.id = UP011; subj.sess(1).eventsFile = '/data/eeg/UP011/behavioral/catFR/session_0/events.mat'
% experiment = 'iCatFR';
%

if ~exist('experiment', 'var')
  expriment = 'unknown';
end

if ~exist(eeg.resDir)
  mkdir(eeg.resDir);
end

% create the eeg struct
eeg = struct('experiment', experiment, 'recordingType', 'iEEG', 'dataroot', dataroot, 'resDir', resDir);

% add eventsFile info for each subj, session
if isstr(sessions)
  run(sessions);
  eeg.subj = subj;
elseif isstruct(sessions)
  eeg.subj = sessions;
end

for s=1:length(eeg.subj)
  
  % find out which ones were good, find out what brain region each was in
  good_chans_file = fullfile(dataroot, eeg.subj(s).id, 'tal', 'good_leads.txt');
  good_chans = textread(good_chans_file, '%n');
  jacksheet = fullfile(dataroot, eeg.subj(s).id, 'docs', 'jacksheet.txt');
  [channels, regions] = textread(jacksheet, '%d%s');
  
  [channels, gidx, cidx] = intersect(good_chans, channels);
  for c=1:length(channels)
    eeg.subj(s).chan(c).number = channels(c);
    eeg.subj(s).chan(c).region = regions{cidx(c)};
  end
  
  for n=1:length(eeg.subj(s).sess)
    eeg.subj(s).sess(n).goodChans = good_chans;
  end
  
  eeg.subj(s).pat = [];
  eeg.subj(s).ana = [];
  
end

% save the struct, which holds filenames of all saved data

save(fullfile(resDir, 'eeg.mat'), 'eeg');

