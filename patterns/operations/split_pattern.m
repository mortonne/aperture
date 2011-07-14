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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

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

% load the pattern to be split
full_pattern = get_mat(pat);

fprintf('splitting pattern %s along %s dimension: ', pat.name, dim_name)

% convenience variables
orig_file = pat.file;
labels = get_dim_labels(pat.dim, dim_name);
all_dim = {':',':',':',':'};
dim_len = size(full_pattern, dim_number);
pat.file = cell(1, dim_len);

full_pat = pat;
dim = get_dim(pat.dim, dim_name);

% split the pattern along the specified dimension
for i = 1:dim_len
  fprintf('%s ', labels{i})

  % get this slice
  ind = all_dim;
  ind{dim_number} = i;
  pattern = full_pattern(ind{:});
  
  pat.dim = set_dim(pat.dim, dim_name, dim(i), 'ws');
  
  % save to disk
  pat.name = sprintf('%s_%s', full_pat.name, labels{i});
  pat.file = fullfile(res_dir, sprintf('%s_%s.mat', filename, labels{i}));
  obj = pat;
  save(pat.file, 'pattern', 'obj')
  full_pat.file{i} = pat.file;
end
fprintf('\n')

pat = full_pat;
pat.orig_file = orig_file;
pat.dim.splitdim = dim_number;

