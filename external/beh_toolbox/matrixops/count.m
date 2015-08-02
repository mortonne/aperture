function value_count = count(data_matrix, value)
% COUNT  Returns the number of times a value occurs in a vector
%
% value_count = count(data_matrix, value)
%
% INPUTS:
% data_matrix:  a matrix of values 
%
%       value:  a scalar value to search for in data_matrix
%
% OUTPUTS:
% value_count: the number of times value occurred in data_matrix
%
% EXAMPLES:
% >> data = [4 4 5 2; 0 7 4 5];
% >> c = count(data, 4)
% c =
%     3
% >> c2 = count(data, 7)
% c2 =
%     1
% >> c3 = count(data, 100)
% c3 =
%     0

% sanity checks:
if length(value) > 1
  error('value must be a scalar')
end

% very simple (perhaps almost naive) implementation:
value_count = nnz(data_matrix == value);

%endfunction