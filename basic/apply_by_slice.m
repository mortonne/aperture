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

mat_ndims = cellfun(@ndims, matrices);

% each matrix must have the same size on iter_dims.  For now,
% assuming this to be true.
in_dim_sizes = size(matrices{1});
all_dims = 1:ndims(matrices{1});
not_iter_dims = ~ismember(all_dims, iter_dims);

% get the size of the output matrix; set all non-iter dims to
% singleton
out_dim_sizes = in_dim_sizes;
out_dim_sizes(not_iter_dims) = 1;
x = nan(out_dim_sizes);

n = 1;
i = repmat({':'}, 1, length(in_dim_sizes));

% run the function on each slice with dark recursive magic
x = eval_dim(matrices, x, i, n, iter_dims, in_dim_sizes, f, varargin);

function out_matrix = eval_dim(in_matrices, out_matrix, i, n, iter_dims, s, f, f_in)
  % in_matrices - complete input matrices
  % out_matrix - output matrix so far
  % i - current indices in the input matrices
  % n - current dimension number
  % s - matrix sizes
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
      % colons should correspond to collapsed dimensions
      out_matrix(i{:}) = f(slices{:}, f_in{:});
    end
  end
%endfunction

