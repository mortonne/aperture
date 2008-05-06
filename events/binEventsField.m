function field = binEventsField(events, bins)
	%BINEVENTSFIELD   Bin an existing events field to make a new one.
	%   FIELD = BINEVENTSFIELD(EVENTS,BINS) where BINS is the name of
	%   one of the fields in EVENTS, is the same as FIELD =      
	%   GETSTRUCTFIELD(EVENTS,FIELDNAME).  If BINS is 'overall,' the
	%   field will have one value for all events.
	%
	%   If BINS is a cell array, each cell is assumed to contain an
	%   argument for FILTERSTRUCT.  FIELD will contain one unique
	%   value for each cell.
	%

	if iscell(bins)
		% assume each cell contains an eventfilter
		field = zeros(1, length(events));
		for i=1:length(bins)
			thisfield = inStruct(events, bins{i});
			field(thisfield) = i;
		end

		elseif strcmp(bins, 'overall')
		% lump all events together
		field = ones(1, length(events));

		elseif isfield(events, bins)
		% each unique value of the field will be used
		field = getStructField(events, bins);

		else
		% no binning will take place
		field = 1:length(events);
	end
