function [index, values] = make_index(varargin)
%MAKE_INDEX   Make an index vector from a set of vectors.
%
%  [index, values] = make_index(i1, i2, i3, ...)
%
%  Create an index that has a unique value for each combination of
%  values for a number of arrays. Each input array can be a numeric
%  array or a cell array of strings.  The returned index vector
%  will contain only consecutive positive integers, with each integer
%  corresponding to a unique set of [i1(j) i2(j) i3(j) ...].
%
%  Note that the mapping of values of index to elements of the input 
%  arrays is arbitrary.
%
%  EXAMPLES:
%   % merge a number of index vectors
%   i1 = [1 2 1 1];
%   i2 = {'eggs', 'spam', 'eggs', 'spam'};
%   [index, values] = make_index(i1, i2);
%   % index: [1 3 1 2]
%   % values: {1 'eggs'; 1 'spam'; 2 'spam'}
%
%   % merge indices that contain NaNs
%   i1 = [1 NaN 3 NaN 2 2];
%   i2 = [1 NaN 2 2 NaN NaN];
%   [index, values] = make_index(i1, i2);
%   % index: [1 NaN 2 NaN NaN NaN]
%   % values: {1 1; 3 2};

% input checks
len = unique(cellfun(@length, varargin));
if length(len)>1
  error('All inputs must have the same length.')
elseif len==0
  index = [];
  values = {};
  return
elseif ~all(cellfun(@isvector, varargin))
  error('All inputs must be vectors.')
end

% make a matrix with all indices, converting all cell arrays
% to integer vectors
index_matrix = NaN(len, length(varargin));
index_values = cell(1, length(varargin));
for i=1:length(varargin)
  this_index = varargin{i};
  if ~(isnumeric(this_index) || iscellstr(this_index))
    error('Input index %d is not an array or a cell array of strings.', i)
  end
  
  [index_values{i}, x, index_matrix(:,i)] = unique(this_index);

  % handle NaNs in this index
  if isnumeric(this_index) && any(isnan(index_values{i}))
    % mark values as a NaN in the index matrix
    bad = find(isnan(index_values{i}));
    ind = index_matrix(:,i);
    ind(ismember(ind, bad)) = NaN;
    index_matrix(:,i) = ind;
    
    % remove from the list of unique values
    index_values{i} = index_values{i}(~isnan(index_values{i}));
  end
  
  % all our values will be stored in cell arrays
  if isnumeric(index_values{i})
    index_values{i} = num2cell(index_values{i});
  end
end

% get unique index combinations
bad_rows = any(isnan(index_matrix), 2);
uniq_rows = unique(index_matrix(~bad_rows,:), 'rows');

% get the corresponding values for each set
values = cell(size(uniq_rows));
for i=1:size(values,2)
  values(:,i) = index_values{i}(uniq_rows(:,i));
end

% map the indices onto the elements
index = NaN(len,1);
for i=1:size(uniq_rows,1)
  tf = ismember(index_matrix, uniq_rows(i,:), 'rows');
  index(tf) = i;
end
