function x = apply_by_group(f, matrices, iter_cell, constant_in, varargin)
%APPLY_BY_GROUP   Iterate over groups of indices to matrices,
%   applying a function.
%
%  x = apply_by_group(f, matrices, iter_cell, constant_in, varargin)
%
%  INPUTS:
%             f:  handle to a function to apply to each slice.  Output
%                 must be a scalar.
%
%      matrices:  cell array of matrices.  Each must have the same size
%                 along each iter_dim.  Other dimensions can be
%                 different.
%
%     iter_cell:  cell array of groups to iterate over, indicating
%                 the groups to be iterated over.  Number of cells
%                 must match the number of dimensions in matrices.
%                 If a cell is empty, this dimension is not
%                 iterated over (all values are passed into the
%                 function).  If a cell has subcells of indices,
%                 then these correspond to the groups that will be
%                 iterated over.  If the cell has the string 'iter' in
%                 it, then every element in this dimension will be
%                 iterated over. 
%
%   constant_in:  cell array of additional inputs to f, after all slices.
%                 These inputs are the same regardless of what slice is
%                 being processed.
%
%  OUTPUTS:
%             x:  matrix of output values.  All empty dimensions in
%                 iter_cell will be singleton.
%
%  ARGS:
%  Optional additional arguments passed in as parameter, value pairs:
%   uniform_output  - if true, output will be an array; if false, output
%                     will be a cell array (true)
%


% input checks
if ~exist('f', 'var') || ~isa(f, 'function_handle')
  error('You must pass a function handle to evaluate.')
elseif ~exist('iter_cell', 'var') || ~iscell(iter_cell) 
  error('You must pass a cell vector of groups to iterate over.')
elseif isempty(iter_cell)
  error('iter_cell cannot be empty.')
elseif ~exist('matrices', 'var') || isempty(matrices)
  error('You must pass a cell array of matrices.')
end
if ~exist('constant_in', 'var')
  constant_in = {};
end
if ~iscell(matrices)
  matrices = {matrices};
end
if ~iscell(constant_in)
  constant_in = {constant_in};
end

% throw an error if a cell in iter_cell has a string other than iter
for i = 1:length(iter_cell)
  for j = 1:length(iter_cell{i})
    if isstr(iter_cell{i}{j})
      if ~strcmp(iter_cell{i}{j},'iter')
	error('string inputs in cells can only be ''iter''');
      end
    end
  end
end

defaults.uniform_output = true;
params = propval(varargin, defaults);

% get the size of the output matrix.
% all dimensions with a corresponding empty cell will be singleton,
% ndims for the output is the 
% highest iter dimension or 2, whichever is higher

for i = 1:length(iter_cell)
  %keyboard
  if isempty(iter_cell{i})
    out_dim_sizes(i) = 1;
    iter_cell{i} = {1:size(matrices{1},i)};
  elseif strcmp(iter_cell{i},'iter')
    out_dim_sizes(i) = size(matrices{1},i);
    iter_cell{i} = num2cell(1:size(matrices{1},i));
    %keyboard
  else
    out_dim_sizes(i) = size(iter_cell{i},2);
  end
%keyboard
end

% these dimensions of the input matrices will be iterated over
iter_dims = find(~cellfun('isempty',iter_cell));
%
%for dim=iter_dim
%  iter_dim_sizes = unique(cellfun('size', matrices, dim));
%  if length(iter_dim_sizes) > 1
%    error('Sizes of matrices are mismatched along dimension %d', dim)
%  end
%  out_dim_sizes(dim) = iter_dim_sizes;
%end

% initialize the output matrix
if params.uniform_output
  x = nan(out_dim_sizes);
else
  x = cell(out_dim_sizes);
end

% get indices that will work with all the input matrices
max_in_dim = max(cellfun(@ndims, matrices));
i = repmat({':'}, 1, max_in_dim);

n = 1;
%keyboard
% run the function on each slice with dark recursive magic
x = eval_dim(matrices, x, i, n, iter_cell, iter_dims, ...
	     out_dim_sizes, f, constant_in);

function out_matrix = eval_dim(in_matrices, out_matrix, i, n, ...
			       iter_cell, iter_dims, s, f, f_in)
  % in_matrices - complete input matrices
  % out_matrix - output matrix so far
  % i - current indices in the input matrices
  % n - current dimension number
  % s - output matrix size
  % f - function to evaluate on each slice
  % f_in - additional inputs
  
  % iterate over the current dimension
  dim = iter_dims(n);
  for j=1:s(dim)
    % update the index
    i{dim} = j;
    %keyboard
    if dim < max(iter_dims)
      % call recursively, using the next iter_dim
      out_matrix = eval_dim(in_matrices, out_matrix, i, n + 1, ...
			    iter_cell, iter_dims, s, f, f_in);
    else
      % we've reached the last iter_dim; grab the current slice
      slices = cell(size(in_matrices));
      % determine the appropriate indices to grab
      for k=1:length(i)
	group_i{k} = iter_cell{k}{i{k}};
      end
      
      for k=1:length(in_matrices)
        slices{k} = in_matrices{k}(group_i{:});
      end

      % call the function to get the output for this slice
      f_out = f(slices{:}, f_in{:});
      
      % place the output; colons should correspond to collapsed 
      % dimensions
      if isnumeric(out_matrix)
        if ~isscalar(f_out)
          error(['Output of f must be scalar, or uniform_output must be set to false.'])
        end
        out_matrix(i{:}) = f_out;
      else
        out_matrix{i{:}} = f_out;
      end
    end
  end
%endfunction
