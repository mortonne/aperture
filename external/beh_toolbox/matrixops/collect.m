function value_counts = collect(data_matrix, values)
% COLLECT  Returns the number of times each of a set of values appears in a
%          data matrix (regardless of where they occur).
%
% INPUTS:
%  data_matrix: a matrix of values to search in
%
%       values: a row vector of values to count in data_matrix
%
% OUTPUTS:
% value_counts: a row vector containing the number of times each value appeared
%               in data_matrix.  value_counts is indexed in the same way as
%               values, i.e., value_counts(i) is the number of times values(i)
%               occurred in data_matrix
%               
% EXAMPLES:
% >> data = [1 1 2 3 5 8;
%            3 3 3 2 2 1];
% >> vals = [1 2 3];
% >> c1 = collect(data, vals)
% c1 =
%      3 3 4
% >> other_vals = [5 8 20 200];
% c2 = collect(data, other_vals)
% c2 =
%      1 1 0 0
%

% sanity!
if ~exist('data_matrix', 'var')
  error('You must pass a data_matrix')
elseif ~exist('values', 'var')
  error('You must pass a vector of values to count')
%elseif size(values, 1) > 1
  %error('values must be a row vector')
  % no it doesn't. This was unnecessarily restrictive.
elseif ~isvector(values)
  error('values must be a vector')
end

% the returned value_counts should be a row vector with the same number of
% columns as values has
value_counts = zeros(1, length(values));
for i = 1:length(values)
  value_counts(i) = count(data_matrix, values(i));
end

%endfunction

