function field = binEventsField(events, bins)
%BINEVENTSFIELD   Bin an existing events field to make a new one.
%   FIELD = BINEVENTSFIELD(EVENTS,BINS) where BINS is the name of
%   one of the fields in EVENTS, is the same as FIELD =      
%   GETSTRUCTFIELD(EVENTS,FIELDNAME).
%
%   If BINS is 'overall,' the
%   field will have one value for all events.
%
%   If BINS is a cell array, and each cell contains a field in EVENTS, 
%   the new field will have a unique value for each combination of the 
%   fields.  Otherwise, each cell is assumed to contain an
%   argument for FILTERSTRUCT.  FIELD will contain one unique
%   value for each cell.
%
%   If BINS is an integer N, events will be randomly divided up 
%   into N bins of equal length.
%

if iscell(bins)
	fnames = fieldnames(events);

	% first check if each string in the cell array is a field
	if sum(~ismember(bins,fnames))==0
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

	else
	% no binning will take place
	field = 1:length(events);
end
