function group_sub = regs_subset(group, ind)
%REGS_SUBSET   Get a subset of conditions for a set of regressors.
%
%  group_sub = regs_subset(group, ind)
%
%  INPUTS:
%   group:  cell array of numeric factors, like those used by the MATLAB
%           statistics toolbox.
%
%     ind:  index indicating a subset of observations to get for all
%           factors.
%
%  OUTPUTS:
%  group_sub:  group with a subset of observations.

group_sub = cell(size(group));
for i = 1:length(group)
  group_sub{i} = group{i}(ind);
end

