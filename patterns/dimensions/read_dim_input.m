function [name, number, long_name] = read_dim_input(dim_input)
%READ_DIM_INPUT   Parse user input indicating a dimension.
%
%  [name, number, long_name] = read_dim_input(dim_input)
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

% input checks
if ~exist('dim_input', 'var')
  error('You must pass dim_input.')
end

% process input
DIM_NAMES = {'ev', 'chan', 'time', 'freq'};
DIM_LONG_NAMES = {'Event', 'Channel', 'Time', 'Frequency'};
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
