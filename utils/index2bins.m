function [bins, values] = index2bins(index)
%INDEX2BINS   Convert an index vector into bins format.
%
%  bins = index2bins(index)
%
%  INPUTS:
%    index:  numeric vector with one unique value for each group.
%
%  OUTPUTS:
%     bins:  cell array with one cell for each unique value of index.
%            Each cell contains the indices of index corresponding to
%            that value.
%
%   values:  array of values corresponding to the bins.

% input checks
if ~isnumeric(index)
  error('index must be numeric.')
elseif ~isvector(index)
  error('index must be a vector.')
end

values = unique(index)';
bins = cell(1, length(values));
for i=1:length(values)
  bins{i} = find(index==values(i));
end

