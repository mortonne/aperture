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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

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

