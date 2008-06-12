function [ev2, events2, bine] = eventBins(ev1, params, events1)
%
%EVENTBINS   Apply bins to an events dimension.
%   [EV2,EVENTS2] = EVENTBINS(EV1,PARAMS) bins the events
%   dimension whose information is stored in EV1 using options in
%   PARAMS, and outputs EV2, a new dimension struct, and EVENTS2,
%   a struct with one field, "type."
%
%   [EV2,EVENTS2,BINE] = EVENTBINS(EV1,PARAMS) also outputs BINE,
%   a cell array of indices of the original events struct for
%   each unique value of EVENTS2.
%

if ~exist('params', 'var')
	params = struct();
end

params = structDefaults(params, 'field', '',  'eventbinlabels', '');

if ~exist('events1', 'var')
	load(ev1.file);
	events1 = events;
end

ev2 = ev1;

% generate a new events field, one value per bin
vec = binEventsField(events1, params.field);

% find the events corresponding to each condition
vals = unique(vec);
ev2.len = length(vals);
for j=1:length(vals)

	if iscell(vals)
		% assume all values are strings
		if ~isempty(params.eventbinlabels)
			events2(j).type = params.eventbinlabels{j};
			else
			events2(j).type = vals{j};
		end
		bine{j} = find(strcmp(vec, vals{j}));

		else
		% values are numeric
		if ~isempty(params.eventbinlabels)
			events2(j).type = params.eventbinlabels{j};
			else
			events2(j).type = vals(j);
		end
		bine{j} = find(vec==vals(j));
	end

end % unique event types
