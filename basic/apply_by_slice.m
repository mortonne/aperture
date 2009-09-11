function x = apply_by_slice(f, matrices, iter_dims, constant_in, varargin)
%APPLY_BY_SLICE   Iterate over slices of matrices, applying a function.
%
%  x = apply_by_slice(f, matrices, iter_dims, constant_in, varargin)
%
%  INPUTS:
%             f:  handle to a function to apply to each slice.  Output
%                 must be a scalar.
%
%      matrices:  cell array of matrices.  Each must have the same size
%                 along each iter_dim.  Other dimensions can be
%                 different.
%
%     iter_dims:  array of dimension numbers, indicating the dimensions
%                 to be iterated over.
%
%   constant_in:  cell array of additional inputs to f, after all slices.
%                 These inputs are the same regardless of what slice is
%                 being processed.
%
%  OUTPUTS:
%             x:  matrix of output values.  All dimensions not listed in
%                 iter_dims will be singleton.
%
%  ARGS:
%  Optional additional arguments passed in as parameter, value pairs:
%   uniform_output  - if true, output will be an array; if false, output
%                     will be a cell array (true)
%
%  EXAMPLES:
%   a = magic(3);
%
%   % get the maximum value, iterating over each row
%   x = apply_by_slice(@max, {a}, 1);
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
if ~exist('constant_in', 'var')
  constant_in = {};
end
if size(iter_dims, 1) > 1
  iter_dims = iter_dims';
end
if ~iscell(matrices)
  matrices = {matrices};
end
if ~iscell(constant_in)
  constant_in = {constant_in};
end

defaults.uniform_output = true;
params = propval(varargin, defaults);

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
if params.uniform_output
  x = nan(out_dim_sizes);
else
  x = cell(out_dim_sizes);
end

% get indices that will work with all the input matrices
max_in_dim = max(cellfun(@ndims, matrices));
i = repmat({':'}, 1, max_in_dim);

n = 1;

% run the function on each slice with dark recursive magic
x = eval_dim(matrices, x, i, n, iter_dims, out_dim_sizes, f, constant_in);

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
