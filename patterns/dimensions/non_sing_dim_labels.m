function [labels, non_sing] = non_sing_dim_labels(dim_info, exclude)
%NON_SING_DIM_LABELS   Get labels for non-singleton dimensions of a pattern.
%
%  [labels, non_sing] = non_sing_dim_labels(dim_info, exclude)
%
%  INPUTS:
%  dim_info:  a dimension info structure.
%
%   exclude:  numbers of dimensions to exclude.
%
%  OUTPUTS:
%    labels:  [1 X N non-singleton dimensions] cell array. Each cell
%             contains a cell array of strings giving the labels for
%             each dimension.
%
%  non_sing:  numbers of each non-singleton dimension.

if ~exist('exclude', 'var')
  exclude = [];
end

pat_size = patsize(dim_info);

non_sing = setdiff(find(pat_size > 1), exclude);
n_non_sing = length(non_sing);
labels = cell(1, n_non_sing);
for i = 1:n_non_sing
  dim_number = non_sing(i);
  labels{i} = get_dim_labels(dim_info, dim_number);
end

