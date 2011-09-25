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

if isnumeric(dim_input)
  % input was dim_input number
  number = dim_input;
  switch number
   case 1
    name = 'ev';
    long_name = 'Event';
    dir_name = 'events';
   case 2
    name = 'chan';
    long_name = 'Channel';
    dir_name = 'channels';
   case 3
    name = 'time';
    long_name = 'Time';
    dir_name = 'time';
   case 4
    name = 'freq';
    long_name = 'Frequency';
    dir_name = 'freq';
  end

elseif ischar(dim_input)
  name = dim_input;
  switch name
   case 'ev'
    number = 1;
    long_name = 'Event';
    dir_name = 'events';
   case 'chan'
    number = 2;
    long_name = 'Channel';
    dir_name = 'channels';
   case 'time'
    number = 3;
    long_name = 'Time';
    dir_name = 'time';
   case 'freq'
    number = 4;
    long_name = 'Frequency';
    dir_name = 'freq';
  end
else
  error('dim_input must be an integer or a string.')
end

