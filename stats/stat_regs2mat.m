function [mat, levels] = stat_regs2mat(x, group, levels)
%STAT_REGS2MAT   Convert vector data and regressors to matrix format.
%
%  [mat, levels] = stat_regs2mat(x, group, levels)
%
%  INPUTS:
%       x:  vector of observed data.
%
%   group:  cell array of numeric factors indicating the condition of
%           each element of x.
%
%  levels:  (optional) cell array indicating the order to place the
%           levels within each factor. Default is to use unique sorted
%           values, i.e. levels{i} = unique(group{i}).
%
%  OUTPUTS:
%      mat:  matrix with the same data as in x, but rearranged so that
%            each dimension represents one of the factors in group. The
%            elements in each dimension are ordered based on the sorted
%            order of the levels of each factor.
%
%   levels:  cell array of numeric labels, indicating the ordering of
%            each dimension in mat.
%
%  EXAMPLE:
%   % data from 3 subjects in each of 4 conditions
%   x = 1:12;
%   group = {[1 1 1 1 2 2 2 2 3 3 3 3]' [1 2 3 4 1 2 3 4 1 2 3 4]'};
%   [mat, levels] = stat_regs2mat(x, group);
%    mat =
%       1  2  3  4
%       5  6  7  8
%       9 10 11 12
%   levels{1}'
%       1  2  3
%   levels{2}'
%       1  2  3  4
%
%   % specifying a different ordering of levels within each factor
%   levels = {[3 2 1]' [1 3 2 4]'};
%   mat = stat_regs2mat(x, group, levels)
%    mat =
%       9 11 10 12
%       5  7  6  8
%       1  3  2  4

if nargin < 3
  levels = cellfun(@unique, group, 'UniformOutput', false);
end

n_levels = cellfun(@length, levels);
if isscalar(n_levels)
  n_levels = [n_levels 1];
end

mat = NaN(n_levels);
ind = cell(1, length(group));
for i = 1:length(x)
  [ind{:}] = ind2sub(n_levels, i);

  for j = 1:length(ind)
    % index of the current level within this factor
    ind{j} = find(levels{j} == group{j}(i));
  end
  mat(ind{:}) = x(i);
end
