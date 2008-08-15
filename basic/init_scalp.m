function exp = init_scalp(subj, resDir, experiment, elecLocsFile)
%INIT_SCALP   Prepare a scalp EEG experiment for analysis.
%   EXP = INIT_SCALP(SUBJ,RESDIR,EXPERIMENT,ELECLOCSFILE) creates an 
%   EXP struct containing the information in the subject structure 
%   SUBJ, and saves EXP in RESDIR/exp.mat.  The optional EXPERIMENT 
%   string specifies what experiment the data are from.  If an
%   ELECLOCSFILE is specified, information about each channel and
%   what region each corresponds to is added to the "chan" struct
%   for each subject.
%
%   Each chan struct contains the following fields for each channel:
%      number - the number assigned to each channel
%      region - the region label (empty if there is no ELECLOCSFILE)
%      label - a unique string for each channel; initialized as
%              num2str(number).
%
%    To each sess struct, a goodChans field is added that lists
%    which channels were "good" for that session.  This is based
%    on each session's *.bad_chan file.
%
%    Example:
%      subj = get_sessdirs('/data/eeg/scalp/ltp/catFR', 'LTP*');
%      resDir = '/home1/mortonne/EXPERIMENTS/catFR';
%      experiment = 'catFR';
%      elecLocsFile = '/home1/mortonne/eeg/GSN200-128chanlocs.txt';
%      exp = init_scalp(subj,resDir,experiment,elecLocsFile);
%
%   See also init_exp, init_iEEG.
%

if ~exist('elecLocsFile', 'var')
  elecLocsFile = '';
end
if ~exist('experiment', 'var')
  expriment = '';
end

% create the exp struct
exp = init_exp(subj, resDir, experiment, 'scalp');

if ~isempty(elecLocsFile)
  % if an electrode locations file is available, read it
  [channels regions] = textread(elecLocsFile, '%d%s'); 
  
  for c=1:length(channels)
    chan(c).number = channels(c);
    chan(c).region = regions{c};
    chan(c).label = num2str(channels(c));
  end
else
  % otherwise, just use channel numbers without regions
  channels = 1:129;
  
  for c=1:length(channels)
    chan(c).number = channels(c);
    chan(c).region = '';
    chan(c).label = num2str(channels(c));
  end
end

for s=1:length(exp.subj)
  % each subject gets the same channel info (assuming same cap types)
  exp.subj(s).chan = chan;
  
  for n=1:length(exp.subj(s).sess)
    
    % attempt to get bad channel information
    bad_chan_dir = fullfile(exp.subj(s).sess(n).dir, 'eeg');
    temp = dir(fullfile(bad_chan_dir, '*.bad_chan'));
    if ~isempty(temp)
      bad_chans = textread(fullfile(bad_chan_dir, temp.name));
    else
      bad_chans = [];
    end
    
    % mark which channels were ok for each session
    exp.subj(s).sess(n).goodChans = setdiff(channels, bad_chans);
  end
end

% save the exp struct updated with channel info
exp = update_exp(exp);
