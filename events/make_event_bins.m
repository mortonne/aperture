function labels = make_event_bins(events, bins)
%MAKE_EVENT_BINS   Divide an events structure into bins.
%
%  labels = make_event_bins(events, bins)
%
%  This function is used to create regressors for statistics
%  and pattern classification.
%
%  INPUTS:
%   events:  an events structure.
%
%     bins:  input that specifies how to divide the events
%            structure into bins (see below).
%
%  OUTPUTS:
%   labels:  a vector or cell array of strings the same length
%            as events, where each unique value indicates one
%            bin. Events that are not placed in any bin are
%            marked with a NaN.
%
%  BINS FORMAT:
%    'field_name'
%      The name of one of the fields. Same as 
%      getStructField(events, 'field_name').
%
%    {'field_name1','field_name2',...}
%      Cell array of fieldnames. Bins will be made such that each 
%      conjuction of the fields will be unique. (BROKEN)
%
%    {'filter1','filter2',...}
%      Cell array of strings that will be input to inStruct to 
%      form each bin.
%
%    number_of_bins
%      Integer specifying the number of bins to randomly divide 
%      events into non-overlapping bins that are of as equal 
%      length as possible.
%
%    'overall'
%      All events will be put into one bin.
%
%    'none'
%      Each event will have its own bin.
%
%  See also patBins, modify_pattern.

% input checks
if ~exist('events','var')
  error('You must pass an events structure.')
  elseif ~isstruct(events)
  error('events must be a structure.')
  elseif ~exist('bins','var')
  error('You must specify how to create the bins.')
end

if iscell(bins)
	% first check if each string in the cell array is a field
	fnames = fieldnames(events);
	if false %sum(~ismember(bins,fnames))==0
		% make the new field a conjunction of multiple fields
		for i=1:length(events)
		  val = '';
		  for j=1:length(bins)
		    val = [val num2str(events(i).(bins{j})) '.'];
		  end
		  labels{i} = val;
		end

		else
		% assume each cell contains an eventfilter
		labels = NaN(1,length(events));
		for i=1:length(bins)
			thisfield = inStruct(events, bins{i});
			labels(thisfield) = i;
		end
	end

	elseif isfield(events, bins)
	% each unique value of the field will be used
	labels = getStructField(events, bins);

	elseif strcmp(bins, 'overall')
	% lump all events together
	labels = ones(1, length(events));

	elseif isnumeric(bins)
	% randomly divide up the events
	events_per_bin = fix(length(events)/bins);
	inds = repmat(1:bins,1,events_per_bin);
	labels = inds(randperm(length(inds)));

	elseif strcmp(bins,'none')
	% no binning will take place
	labels = 1:length(events);
	
	else
	error('Invalid input for bins.')
end
