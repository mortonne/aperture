function pattern = patMeans(pattern, bins)
%PATMEANS   Bin one or more dimensions of a pattern.
%
%  pattern = patMeans(pattern, bins)
%
%  Use this function to average together arbitrary bins for each
%  dimension of a pattern.
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

% input checks
if ~exist('pattern','var')
  error('You must pass an array to be binned.')
  elseif ~isnumeric(pattern)
  error('pattern must be a numeric array.')
  elseif ~exist('bins','var')
  error('You must specify bins to use.')
  elseif ~iscell(bins)
  error('bins must be a cell array.')
end

% a cell array that can be used to index the whole pattern
ALL_CELL = {':',':',':',':'};
ONE_CELL = {1 1 1 1};

% bin one dimension at a time
for i=1:length(bins)
	% if the cell corresponding to this dimension is empty, skip
	if isempty(bins{i})
		continue
	end

	% size of the pattern this iteration
	old_size = size(pattern);
	
	% get cell array with the size of each dimension
	new_size = ONE_CELL; % default each dimension to being singleton
	for j=1:length(old_size)
		new_size{j} = old_size(j);
	end
	
	% update the size of this dimension to what it will
	% be after binning
	new_size{i} = length(bins{i});

  % initialize the var that will hold this mean as it's being
  % created
	temp = NaN(new_size{:});
	
	for j=1:length(bins{i})
	  % check this bin
		if isempty(bins{i}{j})
			fprintf('Warning: Empty Bin in Dimension %d.\n', i);
		end
		
		% get reference for everything going into the bin
		bin_ind = ALL_CELL;
		bin_ind{i} = bins{i}{j};

		% do the average along dimension i
		avg = nanmean(pattern(bin_ind{:}),i);
		if all(isnan(avg(:)))
		  warning('Bin %d of dimension %d contains all NaNs.', j, i)
	  end
	  
	  % get reference for this bin after averaging
		ind = ALL_CELL;
		ind{i} = j;
	  
	  % place this average in the new array
		temp(ind{:}) = avg;
	end
	
	% this dimension is finished; update the pattern, and we're
	% ready to bin the next dimension
	pattern = temp;
end
