function [chan2, binc] = chanBins(chan1, params)
%
%CHANBINS   Apply binning to a channel dimension.
%   [CHAN2] = CHANBINS(CHAN1,PARAMS) bins the channels dimension
%   whose information is stored in CHAN1 using options in PARAMS,
%   and outputs a new chan struct CHAN2.
%
%   [CHAN2,BINC] = CHANBINS(CHAN1,PARAMS) also outputs BINC,
%   a cell array of indices of the original chan struct for
%   each channel group in CHAN2.
%
%   OPTIONAL PARAMS:
%      CHANBINS - a cell array indicating how to make each
%                 channel group; each cell can be a vector
%                 of channel numbers, a cell array of regions,
%                 or a string to be passed into FILTERSTRUCT.
%      CHANBINLABELS - a cell array containing names for each
%                      channel group
%      

if ~exist('params', 'var')
	params = struct();
end

params = structDefaults(params, 'chanbins', {},  'chanbinlabels', {});

if isempty(params.chanbins)
	% no binning will occur
	for c=1:length(chan1)
		binc{c} = c;
	end
	chan2 = chan1;
	return
end

% define the new channel bins
for c=1:length(params.chanbins)

	if ~iscell(params.chanbins)
		% each bin contains just one channel
		binc{c} = params.chanbins(c);

		elseif isnumeric(params.chanbins{c})
		% this bin contains multiple channel numbers
		binc{c} = find(inStruct(chan1, 'ismember(number, varargin{1})', params.chanbins{c}));

		elseif iscell(params.chanbins{c})
		% this bin contains multiple regions
		regions = getStructField(chan1, 'region');
		binc{c} = find(inStruct(chan1, 'ismember(region, varargin{1})', params.chanbins{c}));

		elseif isstr(params.chanbins{c})
		% create the bin using a chanfilter string
		binc{c} = find(inStruct(chan1, 'strcmp(region, varargin{1})', params.chanbins{c}));
	end

	% make the new chan struct
	theseChans = chan1(binc{c});
	chan2(c).number = getStructField(theseChans, 'number');
	chan2(c).region = getStructField(theseChans, 'region');
end

% update the channel labels
for c=1:length(chan2)
	if ~isempty(params.chanbinlabels)
		% use user-specified labels
		chan2(c).label = params.chanbinlabels{c};

		elseif length(unique({chan2.region}))==length(chan2)
		% if each bin has a unique region, we can use that
		chan2(c).label = chan2(c).region;

		else
		% just use the channel number(s)
		chan2(c).label = num2str(chan2(c).number);
	end
end
