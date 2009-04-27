function [dim_name,dim_number,dim_long_name] = read_dim_input(dim_input)
%READ_DIM_INPUT   Parse user input indicating a dimension.
%
%  [dim_name,dim_number,dim_long_name] = read_dim_input(dim_input)
%
%  INPUTS:
%   dim_input:  either a string specifying the name of the dimension 
%               (can be: 'ev', 'chan', 'time', 'freq'), or an integer
%               corresponding to the dimension in the actual matrix.
%
%  OUTPUTS:
%    dim_name:  name of the dimension.
%
%  dim_number:  number of the dimension.
%
%  dim_long_name:  long name of the dimension:
%                  'Events', 'Channel', 'Time', 'Frequency'

% input checks
if ~exist('dim_input','var')
  error('You must pass dim_input.')
end

% process input
DIM_NAMES = {'ev', 'chan', 'time', 'freq'};
DIM_LONG_NAMES = {'Event', 'Channel', 'Time', 'Frequency'};
if isnumeric(dim_input)
  % input was dim_input number
  dim_number = dim_input;

  % get dim_input name
  dim_name = DIM_NAMES{dim_input};

elseif ischar(dim_input)
  dim_name = dim_input;
  % make sure the name is valid
  if ~ismember(dim_name, DIM_NAMES)
    error('Invalid dim_input name: %s', dim_input)
  end

  % get dim_input number
  dim_number = find(strcmp(dim_name, DIM_NAMES));

else
  error('dim_input must be an integer or a string.')
end

dim_long_name = DIM_LONG_NAMES{dim_number};
