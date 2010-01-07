function subj_perfs = get_perf_all_subj(subj, pat_name, stat_name)
%GET_PERF_ALL_SUBJ   Get classifier performance for all subjects.
%
%  subj_perfs = get_perf_all_subj(subj, pat_name, stat_name)
%
%  Exports classifier performance metrics from all subjects.
%  Performance is averaged across all iterations.
%
%  INPUTS:
%        subj:  vector of subject objects.
%
%    pat_name:  string name of the classified pattern.
%
%   stat_name:  string name of the stat object where pattern
%               classification results are saved.
%
%  OUTPUTS:
%  subj_perfs:  [subjects X channels X time X freq] matrix of classifier
%               performance scores.

% inputs
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a vector of subject objects.')
elseif ~exist('pat_name', 'var')
  error('You must specify which pattern was classified.')
elseif ~exist('stat_name', 'var')
  error('You must specify the name of the stat object.')
end

% export all stat objects
stats = getobjallsubj(subj, {'pat', pat_name, 'stat', stat_name});

subj_perfs = [];
for stat=stats
  % load the classifier results for this subject
  load(stat.file);
  
  % get an [iterations X chans X time X freq] performance matrix
  perf = reshape([res.iterations.perf], size(res.iterations));
  
  % average over iterations
  perf = nanmean(perf, 1);
  
  % concatenate
  subj_perfs = cat(1, subj_perfs, perf);
end

