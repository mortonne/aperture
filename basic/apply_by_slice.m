function x = apply_by_slice(f, iter_dims, matrices, varargin)
%APPLY_BY_SLICE   Iterate over slices of matrices, applying a function.
%
%  x = apply_by_slice(f, iter_dims, matrices, varargin)
%
%  INPUTS:
%          f:  handle to a function to apply to each slice.  Output must
%              be a scalar.
%
%  iter_dims:  array of dimension numbers, indicating the dimensions to
%              be iterated over.
%
%   matrices:  cell array of matrices.  Each must have the same size
%              along each iter_dim.  Other dimensions can be different.
%
%   varargin:  additional inputs to f; will be input after all slices.
%
%  OUTPUTS:
%          x:  matrix of output values.  All dimensions not listed in
%              iter_dims will be singleton.
%
%  EXAMPLES:
%   a = magic(3);
%
%   % get the maximum value, iterating over each row
%   x = apply_by_slice(@max, 1, {a});
%
%   % compare to calling max directly; here, you specify the dimension
%   % to operate along, not the dimension to iterate over
%   x = max(a, [], 2);

% input checks
if ~exist('f', 'var') || ~isa(f, 'function_handle')
  error('You must pass a function handle to evaluate.')
elseif ~exist('iter_dims', 'var') || ~isnumeric(iter_dims)
  error('You must pass a vector of dimensions to iterate over.')
elseif isempty(iter_dims)
  error('iter_dims cannot be empty.')
elseif ~exist('matrices', 'var') || isempty(matrices)
  error('You must pass a cell array of matrices.')
end
if size(iter_dims, 1) > 1
  iter_dims = iter_dims';
end
if ~iscell(matrices)
  matrices = {matrices};
end

% get the size of the output matrix.
% all non-iter dimensions will be singleton, ndims for the output is the
% highest iter dimension or 2, whichever is higher
out_dim_sizes = ones(1, max([iter_dims 2]));
for dim=iter_dims
  iter_dim_sizes = unique(cellfun('size', matrices, dim));
  if length(iter_dim_sizes) > 1
    error('Sizes of matrices are mismatched along dimension %d', dim)
  end
  out_dim_sizes(dim) = iter_dim_sizes;
end

% initialize the output matrix
x = nan(out_dim_sizes);

% get indices that will work with all the input matrices
max_in_dim = max(cellfun(@ndims, matrices));
i = repmat({':'}, 1, max_in_dim);

n = 1;

% run the function on each slice with dark recursive magic
x = eval_dim(matrices, x, i, n, iter_dims, out_dim_sizes, f, varargin);

function out_matrix = eval_dim(in_matrices, out_matrix, i, n, iter_dims, s, f, f_in)
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
    
    if dim < length(iter_dims)
      % call recursively, using the next iter_dim
      out_matrix = eval_dim(in_matrices, out_matrix, i, n + 1, iter_dims, s, ...
                            f, f_in);
    else
      % we've reached the last iter_dim; grab the current slice
      slices = cell(size(in_matrices));
      for k=1:length(in_matrices)
        slices{k} = in_matrices{k}(i{:});
      end
      
      % call the function to get the output for this slice
      f_out = f(slices{:}, f_in{:});
      if ~isscalar(f_out)
        error('Output of f must be scalar.')
      end
      
      % place the output; colons should correspond to collapsed 
      % dimensions
      out_matrix(i{:}) = f_out;
    end
  end
%endfunction

