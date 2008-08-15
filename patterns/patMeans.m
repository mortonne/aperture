function pattern = patMeans(pattern, bins)
%PATMEANS   Bin one or more dimensions of a pattern.
%   PATTERN = PATMEANS(PATTERN,BINS) applies binning to PATTERN
%   according to the cell array BINS, a cell array with ndim(PATTERN)
%   cells, each of which contains a cell array where each cell holds
%   the indices corresponding to one bin.
%
%   BINS can be created using patBins.
%
%   Example:
%    params = struct('fields','recalled', ...
%                    'eventbinlabels', {'recalled','not recalled'});
%    [pat,bins] = patBins(pat,params);
%    pattern = loadPat(pat);
%    pattern = patMeans(pattern,bins);
%
%   See also modify_pats, patBins, patFilt.
%

allcell = {':',':',':',':'};
for i=1:length(bins)

	% if the cell corresponding to this dimension is empty, skip
	if isempty(bins{i})
		continue
	end

	% get vector with size of the pattern before binning this dim
	rawsize = size(pattern);
	oldSize = {1,1,1,1};
	for j=1:length(rawsize)
		oldSize{j} = rawsize(j);
	end
	oldSize{i} = length(bins{i});

	temp = NaN(oldSize{:});
	for j=1:length(bins{i})
		if isempty(bins{i}{j})
			fprintf('Warning: Empty Bin in Dimension %d.\n', i);
		end
		
		% get reference for the new bin
		ind = allcell;
		ind{i} = j;

		% get reference for everything going into the bin
		binInd = allcell;
		binInd{i} = bins{i}{j};

		% do the average
		temp(ind{:}) = nanmean(pattern(binInd{:}),i);
	end
	pattern = temp;
end
