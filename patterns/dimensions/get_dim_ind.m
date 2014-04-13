function ind = get_dim_ind(dim_info, dim_id, label)
%GET_DIM_IND   Get the numeric index for an element of a dimension.
%
%  ind = get_dim_ind(dim_info, dim_id, label)
%
%  INPUTS:
%  dim_info:  structure with information about the dimensions of a
%             pattern.  (normally stored in pat.dim).
%
%    dim_id:  either a string specifying the name of the dimension
%             (can be: 'ev', 'chan', 'time', 'freq'), or an integer
%             corresponding to the dimension in the actual matrix.
%
%     label:  string giving the label for an element of the dimension.
%             May also specify a numeric index, which will be
%             checked for validity.
%
%  OUTPUTS:
%       ind:  index for the requested element in the pattern matrix.
%
%  EXAMPLE:
%   get_dim_ind(pat.dim, 'chan', {'Fz' 'Cz' 'Oz' 'Pz'})
%     11 129  75  62

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

labels = get_dim_labels(dim_info, dim_id);
if isnumeric(label)
  % check if this index is in bounds
  for i = 1:length(label)
    if label(i) < 1 || label(i) > patsize(dim_info, dim_id)
      [dim_name, ~, long_name] = read_dim_input(dim_id);
      error('%s index out of bounds: %d.', long_name, label(i))
    end
  end
  ind = label;
elseif ~all(ismember(label, labels))
  % this label does not exist in the dimension
  [dim_name, ~, long_name] = read_dim_input(dim_id);
  if ischar(label)
    error('%s not found: %s', long_name, label)
  else
    error('%s indices not found.', long_name)
  end
elseif ischar(label)
  % the label is present; return its index
  ind = find(strcmp(label, labels));
elseif iscellstr(label)
  % specified multiple labels; return indices in requested order
  [~, ind] = ismember(label, labels);
end
