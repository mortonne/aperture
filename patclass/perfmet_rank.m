function perfmet = perfmet_rank(acts, targs, scratchpad, varargin)
%PERFMET_PERM   Calculate a performance metric and bootstrap distribution.
%
%  perfmet = perfmet_perm(acts, targs, scratchpad)
%
%  INPUTS:
%        args:
%
%       targs:
%
%  scratchpad:
%
%  OUTPUTS:
%     perfmet:

if ~exist('scratchpad', 'var')
  scratchpad = [];
end

[n_units, n_timepoints] = size(acts);

perfmet.perf = NaN;
perfmet.rank = NaN(1, n_timepoints);
perfmet.maxrank = n_units;
answer_acts = acts(logical(targs))';
for i=1:n_timepoints
  sorted = sort(acts(:,i));
  perfmet.rank(i) = find(answer_acts(i) == sorted);
end

perfmet.perf = mean(perfmet.rank);
perfmet.scratchpad = [];

