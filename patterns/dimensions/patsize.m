function D = patsize(dim_info, dim)
%PATSIZE   Get the size of a pattern from its dim structure.
%
%  D = patsize(dim_info, dim)
%
%  INPUTS:
%  dim_info:  structure containing information about the dimensions of a
%             pattern.
%
%       dim:  optional; the dimension to return. If omitted, an array
%             with the size of each dimension is returned. Can be either
%             the number of a dimension in the pattern matrix, or the
%             name of one the dimensions ('ev','chan','time','freq').
%
%  OUTPUTS:
%         D:  an array with the size of the requested dimension(s).

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

% input checks
if ~exist('dim', 'var')
  dim = 1:4;
elseif ischar(dim)
  dim = {dim};
end

% mapping between fields and dimension numbers
for i = 1:length(dim)
  if iscell(dim)
    this_dim = dim{i};
  else
    this_dim = dim(i);
  end
  
  D(i) = get_dim_len(dim_info, read_dim_input(this_dim));
end

function len = get_dim_len(dim_info, dim_name)

  if isfield(dim_info.(dim_name), 'len')
    len = dim_info.(dim_name).len;
  else
    dim = get_dim(dim_info, dim_name);
    len = length(dim);
  end

