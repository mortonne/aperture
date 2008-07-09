function exp = init_iEEG(subj,resDir,experiment)
%
%INIT_IEEG   Prepare an intracranial EEG experiment for analysis.
%   EXP = INIT_IEEG(SUBJ,RESDIR,EXPERIMENT) creates an EXP struct
%   containing the information in the subject structure SUBJ, and
%   saves EXP in RESDIR/exp.mat.  The optional EXPERIMENT string specifies
%   what experiment the data are from.
%
%   In EXP, a "chan" struct is added to each subj to keep track
%   of the electrodes for that subject.  The chan struct contains
%   the following fields for each channel:
%      number - the number assigned to each channel
%      region - the region label used in the subject's jacksheet
%      label - a unique string for each channel; initialized as
%              num2str(number).
%
%    To each sess struct, a goodChans field is added that lists
%    which channels were "good" for that subject.  This is based
%    on each subject's good_leads.txt file.
%

if ~exist('experiment', 'var')
  expriment = '';
end

% create the exp struct
exp = init_exp(subj, resDir, experiment, 'iEEG');

for s=1:length(exp.subj)

  % find out what brain region each channel was in
  jacksheet = fullfile(exp.subj(s).dir, 'docs', 'jacksheet.txt');
  [channels, regions] = textread(jacksheet, '%d%s');
  
  % find out which channels were good
  good_chans_file = fullfile(exp.subj(s).dir, 'tal', 'good_leads.txt');
  good_chans = textread(good_chans_file, '%n');

  % create the chan struct for this subject
  [channels, gidx, cidx] = intersect(good_chans, channels);
  for c=1:length(channels)
    exp.subj(s).chan(c).number = channels(c);
    exp.subj(s).chan(c).region = regions{cidx(c)};
    exp.subj(s).chan(c).label = num2str(channels(c));
  end
  
  % write out the list of which channels were good for this session
  for n=1:length(exp.subj(s).sess)
    exp.subj(s).sess(n).goodChans = good_chans;
  end
  
end

% save the exp struct updated with channel info
exp = update_exp(exp);
