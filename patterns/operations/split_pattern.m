function pat = split_pattern(pat, dimension, res_dir)
%SPLIT_PATTERN   Resave a pattern in slices along one dimension.
%
%  Takes an existing pattern that is saved as one matrix, splits it into
%  slices along a given dimension, and resaves the pattern with one file
%  per slice.
%
%  pat = split_pattern(pat, dimension, res_dir)
%
%  INPUTS:
%        pat:  pat object that corresponds to the pattern that is to be
%              split.
%
%  dimension:  dimension along which to split the pattern. Can be either
%              a string specifying the name of the dimension (can be:
%              'ev', 'chan', 'time', 'freq'), or an integer
%              corresponding to the dimension in the actual matrix.
%
%    res_dir:  directory to save the split pattern files. Default is
%              the same directory as pat.file.
%
%  OUTPUTS:
%        pat:  pat object with the pat.file field modified; it is now
%              a cell array of files, with one cell for each slice of
%              the pattern.
%
%  NOTES:
%   This currently keeps the full pattern file, and just changes
%   the references in pat.file.

% input checks
if ~exist('pat', 'var')
  error('You must input a pattern object.')
end
if ~exist('dimension', 'var')
  dimension = 'chan';
end
[temp, filename] = fileparts(pat.file);
if ~exist('res_dir', 'var')
  % use the parent directory of the pattern
  res_dir = temp;
elseif ~exist(res_dir, 'dir')
  % make sure the new directory exists
  mkdir(res_dir);
end

% parse the dimension input
[dim_name, dim_number] = read_dim_input(dimension);

% save info in the pat object
pat.dim.splitdim = dim_number;

% load the pattern to be split
if ~exist(pat.file, 'file')
  error('%s not found.', pat.file)
end
full_pattern = get_mat(pat);

fprintf('splitting pattern %s along %s dimension: ', pat.name, dim_name)

% convenience variables
labels = get_dim_labels(pat.dim, dim_name);
all_dim = {':',':',':',':'};
dim_len = size(full_pattern, dim_number);
pat.file = cell(1, dim_len);

% split the pattern along the specified dimension
for i=1:dim_len
  fprintf('%s ', labels{i})
  % get this slice
  ind = all_dim;
  ind{dim_number} = i;
  pattern = full_pattern(ind{:});
  
  % save to disk
  pat.file{i} = fullfile(res_dir, sprintf('%s_%s.mat', filename, labels{i}));
  save(pat.file{i}, 'pattern')
end
fprintf('\n')
