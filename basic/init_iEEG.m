function exp = init_iEEG(subj,res_dir,experiment,params)
%INIT_IEEG   Prepare an intracranial EEG experiment for analysis.
%
%  exp = init_iEEG(subj, res_dir, experiment, params)
%
%  INPUTS:
%        subj:  subject structure. See get_sessdirs for details.
%
%     res_dir:  results directory; the exp structure will be saved 
%               in [res_dir]/exp.mat.
%
%  experiment:  optional string indicating the name of the experiment.
%
%      params:  structure specifying options. See below for details.
%
%  OUTPUTS:
%         exp:  experiment object. Contains the input subject structure,
%               with added information about each subject's channels.
%
%  PARAMS:
%  jacksheet       - path to the jacksheet file.
%
%  good_leads_file - path to a text file with one electrode number per
%                    row, indicating all electrodes that are "good".
%  
%  NOTES:
%  The output exp structure contains information about each subject's
%  channels in subfields of exp.subj.chan:
%    number - the number assigned to each channel
%    region - the region label used in the subject's jacksheet
%    label - a unique string for each channel; initialized as 
%            num2str(number).
%
%  To each sess struct, a goodChans field is added that lists
%  which channels were "good" for that subject.  This is based
%  on each subject's good_leads.txt file.
%
%  See also init_exp, init_scalp.

% input checks
if ~exist('params', 'var')
  params = struct;
end
if ~exist('experiment', 'var')
  experiment = '';
end
if ~exist('res_dir','var')
  res_dir = '';
end
if ~exist('subj','var')
  error('You must pass a subj object.')
end

% parse parameters
params = structDefaults(params,'jacksheet',fullfile('docs','jacksheet.txt'), 'good_leads_file',fullfile('tal','good_leads.txt'));

% create the exp struct
exp = init_exp(subj, res_dir, experiment, 'iEEG');

for s=1:length(exp.subj)
  % get channel numbers and labels from the jacksheet
  jacksheet = fullfile(exp.subj(s).dir, params.jacksheet);
  [channels, regions] = textread(jacksheet, '%d%s');
  
  % get a list of "good" channel numbers
  good_chans_file = fullfile(exp.subj(s).dir, params.good_leads_file);
  good_chans = textread(good_chans_file, '%n');

  % only include the good channels
  [channels, gidx, cidx] = intersect(good_chans, channels);

  % create the chan struct for this subject
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

% update the exp object
exp = update_exp(exp);
