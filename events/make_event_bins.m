function bin_labels = make_event_bins(events, bins)
%MAKE_EVENT_BINS   Divide an events structure into bins.
%
%  bin_labels = make_event_bins(events, bins)
%
%  This function is used to create regressors for statistics
%  and pattern classification.
%
%  INPUTS:
%      events:  an events structure.
%
%        bins:  input that specifies how to divide the events
%               structure into bins. Form can be:
%
%               'field_name'
%                 The name of one of the fields. Same as
%                 getStructField(events, 'field_name').
%
%               {'field_name1','field_name2',...}
%                 Cell array of fieldnames. Bins will be made
%                 such that each conjuction of the fields will
%                 be unique.
%
%               {'filter1','filter2',...}
%                 Cell array of strings that will be input to
%                 inStruct to form each bin. Note that with
%                 this option, it is possible to make overlapping
%                 bins.
%
%               number_of_bins
%                 Integer specifying the number of bins to
%                 randomly divide events into non-overlapping
%                 bins that are of as equal length as possible.
%
%               'overall'
%                 All events will be put into one bin.
%
%               'none'
%                 Each event will have its own bin.
%
%  OUTPUTS:
%  bin_labels:  a vector or cell array of strings the same length
%               as events, where each unique value indicates one
%               bin.

% input checks
if ~exist('events','var')
  error('You must pass an events structure.')
  elseif ~isstruct(events)
  error('events must be a structure.')
  elseif ~exist('bins','var')
  error('You must specify how to create the bins.')
end

if iscell(bins)
	fnames = fieldnames(events);

	% first check if each string in the cell array is a field
	if false %sum(~ismember(bins,fnames))==0
		% make the new field a conjunction of multiple fields
		for i=1:length(events)
		  val = '';
		  for j=1:length(bins)
		    val = [val num2str(events(i).(bins{j})) '.'];
		  end
		  field{i} = val;
		end

		else
		% assume each cell contains an eventfilter
		field = NaN(1,length(events));
		for i=1:length(bins)
			thisfield = inStruct(events, bins{i});
			field(thisfield) = i;
		end
	end

	elseif isfield(events, bins)
	% each unique value of the field will be used
	field = getStructField(events, bins);

	elseif strcmp(bins, 'overall')
	% lump all events together
	field = ones(1, length(events));

	elseif isnumeric(bins)
	% randomly divide up the events
	eventsPerBin = fix(length(events)/bins);
	inds = repmat(1:bins,1,eventsPerBin);
	field = inds(randperm(length(inds)));

	elseif strcmp(bins,'none')
	% no binning will take place
	field = 1:length(events);
	
	else
	error('Invalid input for bins.')
end
