function [name, number, long_name, dir_name] = read_dim_input(dim_input)
%READ_DIM_INPUT   Parse user input indicating a dimension.
%
%  [name, number, long_name, dir_name] = read_dim_input(dim_input)
%
%  INPUTS:
%  dim_input:  either a string specifying the name of the dimension
%              (can be: 'ev', 'chan', 'time', 'freq'), or an integer
%              corresponding to the dimension in the actual matrix.
%
%  OUTPUTS:
%       name:  name of the dimension.
%
%     number:  number of the dimension.
%
%  long_name:  long name of the dimension:
%              'Events', 'Channel', 'Time', 'Frequency'
%
%   dir_name:  name for the dim's directory.

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
if ~exist('dim_input', 'var')
  error('You must pass dim_input.')
end

% process input
DIM_NAMES = {'ev', 'chan', 'time', 'freq'};
DIM_LONG_NAMES = {'Event', 'Channel', 'Time', 'Frequency'};
DIM_DIR_NAMES = {'events', 'channels', 'time', 'freq'};
if isnumeric(dim_input)
  % input was dim_input number
  number = dim_input;
  if ~ismember(number, 1:length(DIM_NAMES))
    error('Invalid dim_input number: %d', dim_input)
  end
  
  % get dim_input name
  name = DIM_NAMES{dim_input};

elseif ischar(dim_input)
  name = dim_input;
  % make sure the name is valid
  if ~ismember(name, DIM_NAMES)
    error('Invalid dim_input name: "%s"', dim_input)
  end

  % get dim_input number
  number = find(strcmp(name, DIM_NAMES));

else
  error('dim_input must be an integer or a string.')
end

long_name = DIM_LONG_NAMES{number};
dir_name = DIM_DIR_NAMES{number};

