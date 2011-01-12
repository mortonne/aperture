function vals = get_dim_vals(dim_info, dim_id)
%GET_DIM_VALS   Get the numeric values of a dimension.
%
%  vals = get_dim_vals(dim_info, dim_id)
%
%  INPUTS:
%  dim_info:  structure with information about the dimensions of a
%             pattern.  (normally stored in pat.dim).
%
%    dim_id:  either a string specifying the name of the dimension
%             (can be: 'ev', 'chan', 'time', 'freq'), or an integer
%             corresponding to the dimension in the actual matrix.
%
%  OUTPUTS:
%      vals:  vector of numeric values for the requested dimension.

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
if ~exist('dim_info', 'var') || ~isstruct(dim_info)
  error('You must pass a dim info structure.')
elseif ~exist('dim_id', 'var')
  error('You must indicate the dimension.')
elseif ~(ischar(dim_id) || isnumeric(dim_id))
  error('dim_id must be a string or an integer.')
end

% get the short name of the dimension
dim_name = read_dim_input(dim_id);

switch dim_name
 case {'ev'}
  % these dimensions don't really have numeric values; just return the
  % indices
  vals = 1:patsize(dim_info, dim_id);
 case {'chan'}
  % return the channel number
  dim = get_dim(dim_info, dim_name);
  if ~isfield(dim, 'number')
    error('Channel dimension must contain a "number" field.')
  end
  vals = [dim.number];
 case {'time', 'freq'}
  dim = get_dim(dim_info, dim_name);
  if ~isfield(dim, 'avg')
    error('time and frequency dimensions must contain an "avg" field.')
  end
  vals = [dim.avg];
end

