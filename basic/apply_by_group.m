function x = apply_by_group(f, matrices, iter_cell, constant_in, varargin)
%APPLY_BY_GROUP   Apply a function to index groups of matrices.
%
%  x = apply_by_group(f, matrices, iter_cell, constant_in, ...)
%
%  INPUTS:
%            f:  handle to a function to apply to each slice. Output
%                must be a scalar.
%
%     matrices:  cell array of matrices containing data to be passed
%                into f.
%
%    iter_cell:  cell array with one element for each dimension of the
%                matrices.
%
%                Each iter_cell{i} may contain:
%                 'iter'      - each element of dimension i will be
%                               iterated over. All matrices must have
%                               the same size on dimension i.
%                 []          - an empty array indicates no iteration;
%                               all elements of dimension i will be used
%                               at once.
%                 {1:4, 2:15} - a cell array indicates that multiple
%                               groups will be used. iter_cell{i}{j}
%                               contains the indices for group j. All
%                               matrices must have the same size on
%                               dimension i.
%
%  constant_in:  cell array of additional inputs to f, after all
%                slices. These inputs are the same regardless of what
%                slice is being processed.
%
%  OUTPUTS:
%            x:  array of output values.  All empty dimensions in
%                iter_cell will be singleton.
%
%  ARGS:
%  Optional additional arguments passed in as parameter, value pairs:
%   uniform_output - if true, output will be an array; if false, output
%                    will be a cell array (true)
%
%  EXAMPLE:
%   % get sums over arbitrary groups of columns in a matrix
%   >> a = [1:4; 5:8];
%   >> x = apply_by_group(@sum, {a}, {'iter', {1:2, 2:4, 3}})
%    x =
%         3  9  3
%        11 21  7
%
%   % operate on matrices with different number of columns
%   >> b = [4; 2];
%   >> x = apply_by_group(@(x,y) sum(x * y), {a, b}, {'iter', []})
%    x =
%        40
%        52

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
if isscalar(iter_cell)
  iter_cell = [iter_cell {{}}];
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
if any(cellfun(@(x) iscellstr(x) && ~all(strcmp(x, 'iter')), iter_cell))
  error('string inputs in cells can only be ''iter''.')
elseif any(cellfun(@(x) ~(isvector(x) || isempty(x)), iter_cell))
  error('each cell in iter_cell must either be empty or contain a vector.')
end

defaults.uniform_output = true;
params = propval(varargin, defaults);

% get dimensions of the input matrices that will be iterated over
% all dimensions with a corresponding empty cell will be singleton
iter_dims = find(~cellfun('isempty', iter_cell));

% get the size of the output matrix; ndims for the output is the 
% highest iter dimension or 2, whichever is higher
out_dim_sizes = ones(1, max([iter_dims 2]));
for i = 1:length(iter_cell)
  if isempty(iter_cell{i})
    % all indices will be passed in at once, and this dimension will be
    % collapsed
    out_dim_sizes(i) = 1;
    iter_cell{i} = {':'};
    
  elseif strcmp(iter_cell{i}, 'iter')
    % each element will be passed in separately, and will appear in
    % the output
    dim_size = unique(cellfun('size', matrices, i));
    if ~isscalar(dim_size)
      error('Sizes of matrices are mismatched along dimension %d.', i)
    end
    out_dim_sizes(i) = dim_size;
    iter_cell{i} = num2cell(1:dim_size);
    
  elseif iscell(iter_cell{i})
    % each output element will correspond to a group of indices
    out_dim_sizes(i) = length(iter_cell{i});
    
  else
    error('iter_cell has an invalid format.')
  end
end

% initialize the output matrix
if params.uniform_output
  x = NaN(out_dim_sizes);
else
  x = cell(out_dim_sizes);
end

% get indices that will work with all the input matrices
max_in_dim = max([length(iter_cell) cellfun(@ndims, matrices)]);

% loop over elements of the output matrix
for i = 1:prod(out_dim_sizes)
  % output indices
  output_ind = repmat({':'}, 1, max_in_dim);
  [output_ind{1:length(out_dim_sizes)}] = ind2sub(out_dim_sizes, i);
  
  % get the input indices for this output element
  input_ind = cell(1, max_in_dim);
  for j = 1:max_in_dim
    input_ind{j} = iter_cell{j}{output_ind{j}};
  end

  % build the inputs
  slices = cell(size(matrices));
  for j = 1:length(matrices)
    try
      slices{j} = matrices{j}(input_ind{:});
    catch err
      if strcmp(err.identifier, 'MATLAB:badsubscript')
        error('iter_cell exceeds dimensions of matrix %d.', j);
      else
        rethrow(err)
      end
    end
  end
  
  % get the output for this slice
  f_out = f(slices{:}, constant_in{:});
  
  % place the output (colons should correspond to collapsed dims)
  if isnumeric(x)
    if ~isscalar(f_out)
      error(['Output of f must be scalar, or uniform_output must be set to false.'])
    end
    x(output_ind{:}) = f_out;
  else
    x{output_ind{:}} = f_out;
  end
end

