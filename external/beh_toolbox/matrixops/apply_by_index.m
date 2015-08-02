function [results, result_index] = apply_by_index(f, index, dim, ...
                                                  matrices, varargin)
%APPLY_BY_INDEX   Apply a function to subsets of arrays.
%
%  Applies f on a per-subject, per-session, or per-<other index> basis
%  to each of a number of matrices.
%
%  [results, uniq_index] = apply_by_index(f, index, dim, matrices, ...)
%
%  INPUTS: 
%         f:  handle for a function which accepts as its first
%             arguments the submatrices of each of the matrices which
%             correspond to a single identifier. That is, the first
%             argument to f will be a slice of matrices{1}; the second
%             argument to f will be a slice of matrices{2}, etc. f
%             should always return a matrix of the same size along all
%             dimensions except that specified by dim.  Any additional
%             arguments to this function will be supplied to f
%             after the matrices. It will be called this way:
%               results = f(submatrices{:}, varargin{:})
%             where each submatrices{i} is matrices{i}(find(index == s),:)
%             for some s in index and i in 1:length(matrices).
%
%     index:  vector containing an identifier for each row of the
%             matrices; that is, for all M in matrices:
%              1) length(index) should be the same as size(M, 1) 
%              2) index(i) should be an identifier for the data in
%              M(i, :), e.g., a subject number or session number.
% 
%       dim:  the dimension along which to concatenate when constructing
%             the results array.
%
%  matrices:  cell array containing matrices whose rows represent data
%             which is identified by the values of the index vector,
%             e.g., {data.recalls, data.times}.
%
%  OUTPUTS:
%       results:  array containing the results of applying f to the 
%                 sub-matrices belonging to a particular index
%                 identifier, with the results of different identifiers
%                 arrayed along dimsension dim.
%
%  result_index:  column vector which indexes the results array.  The
%                 indices of a value v in result_index are the
%                 indices of the results matrix along dimension dim
%                 which correspond to the results for that index,
%                 i.e., the result of applying f to the
%                 sub-matrices for index==v.
% 
%  Here is a graphical depiction of the operation:
%                 INPUTS                               OUTPUTS
%  index        M1            M2              results          result_index
%   |1|     | M1_id1 |  | M2_id1 |     | f(M1_id1, M2_id1) |       |1| 
%   |1|     |   ...  |  |   ...  |  -> | f(M1_id2, M2_id2) |       |2| 
%   |2|     | M1_id2 |  | M2_id2 | 
%   |2|     |   ...  |  |   ...  |     

% sanity checks
if ~isa(f, 'function_handle')
  error('f must be a function handle')
elseif ~exist('matrices', 'var') || isempty(matrices) || ~iscell(matrices)
  error('You need to pass a cell array of data matrices')
elseif ~exist('index', 'var') || isempty(index)
  error('You need to pass an index vector')
elseif ~exist('dim', 'var') || isempty(dim)
  error('You must indicate which dimension to concatenate along.')
end
matrices_num_rows = cellfun('size', matrices, 1);
if any(matrices_num_rows~=length(index))
  error('The index vector must be the same length as height of all matrices')
end

% initialize outputs
if isrow(index)
  index = index';
end
uniq_index = unique(index); 
results = [];
result_index = [];

% bust up matrices into submatrices by the identifiers in index,
% apply f to the submatrices, and put the results in the output
% matrix
len_matrices = length(matrices);
for identifier=uniq_index'
  % get the row indices where the index has the identifier value
  M_row_indices = index==identifier; 

  % construct the cell array of submatrices of this subject's data
  submatrices = cell(1, len_matrices);
  for j=1:len_matrices
    submatrices{j} = matrices{j}(M_row_indices, :);
  end

  % apply f to the submatrices and append the output
  % to the result matrix. cat will throw an error if
  % we try to concatenate arrays that have different sizes
  % on any dimension other than dim.
  result_for_index = f(submatrices{:}, varargin{:});
  results = cat(dim, results, result_for_index);

  % making result_index follow an arbitrary dimension is too complicated...
  % so I'm sticking with a column vector.  None of the higher-up functions
  % seem to use it now anyway.
  result_index = cat(1, result_index, ...
                     repmat(identifier, size(result_for_index, dim), 1));
end
%endfunction
