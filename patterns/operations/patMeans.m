function pattern = patMeans(pattern, bins, f, varargin)
%PATMEANS   Bin one or more dimensions of a pattern.
%
%  Use this function to average together arbitrary bins for each
%  dimension of a pattern.
%
%  pattern = patMeans(pattern, bins, f)
%
%  INPUTS:
%  pattern:  the array to be binned.
%
%     bins:  a cell array with one cell for each dimension of
%            pattern. Each cell contains a cell array which defines 
%            the bins for that dimension; each cell contains the
%            indices for one bin. The cell corresponding to a
%            dimension can also be empty, to indicate that dimension
%            should not be binned.
%
%        f:  function to apply to each bin. Must be of the form:
%             y = f(x, dim)
%            where dim indicates the dimension of x that must be
%            collapsed in the output y.
%
%  OUTPUTS:
%  pattern:  the modified array.
%
%  EXAMPLE:
%   % create a random 10x20x30 array
%   pattern = rand(10,20,30);
%
%   % make bins for the first and second dimensions, while leaving
%   % the third dimension as-is. Note that we are using overlapping
%   % bins for the first dimension.
%   bins = {{1:5, 4:6}, {10:20}, {}};
%
%   % average over the indices in each bin to make a 2x1x30 array
%   pattern = patMeans(pattern, bins);
%
%   See also modify_pattern, patBins, patFilt.

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
if ~exist('pattern', 'var')
  error('You must pass an array to be binned.')
elseif ~isnumeric(pattern)
  error('pattern must be a numeric array.')
elseif ~exist('bins', 'var')
  error('You must specify bins to use.')
elseif ~iscell(bins)
  error('bins must be a cell array.')
end
if ~exist('min_samp', 'var')
  min_samp = [];
end

% a cell array that can be used to index the whole pattern
ALL_CELL = {':',':',':',':'};
ONE_CELL = {1 1 1 1};

% bin one dimension at a time
for i = 1:length(bins)
  % if the cell corresponding to this dimension is empty, skip
  if isempty(bins{i})
    continue
  end

  % size of the pattern this iteration
  old_size = size(pattern);
  
  % get cell array with the size of each dimension
  new_size = ONE_CELL; % default each dimension to being singleton
  for j = 1:length(old_size)
    new_size{j} = old_size(j);
  end
  
  % update the size of this dimension to what it will
  % be after binning
  new_size{i} = length(bins{i});

  % initialize the var that will hold this mean as it's being
  % created
  temp = NaN(new_size{:}, class(pattern));
  
  for j = 1:length(bins{i})
    % check this bin
    if isempty(bins{i}{j})
      warning('eeg_ana:patBinEmpty', ...
              'Warning: Empty Bin in Dimension %d.\n', i);
    end
    
    % get reference for everything going into the bin
    bin_ind = ALL_CELL;
    bin_ind{i} = bins{i}{j};

    % do the average along dimension i
    % x = pattern(bin_ind{:});
    % %if ~isempty(min_samp) && nnz(~isnan(x)) / numel(x) < min_samp
    % if ~isempty(min_samp) && nnz(~isnan(x)) < min_samp
    %   % leave this bin as NaNs
    %   fprintf('rm %d:%d ', i,j)
    %   continue
    % end

    % avg = nanmean(x,i);
    % if nnz(isnan(avg)) == numel(avg)
    %   warning('eeg_ana:patBinAllNaNs', ...
    %           'Bin %d of dimension %d contains all NaNs.', j, i)
    % end
    
    % get reference for this bin after averaging
    ind = ALL_CELL;
    ind{i} = j;
    
    % place this average in the new array
    % temp(ind{:}) = avg;
    temp(ind{:}) = f(pattern(bin_ind{:}), i, varargin{:});
  end
  
  % this dimension is finished; update the pattern, and we're
  % ready to bin the next dimension
  pattern = temp;
end
