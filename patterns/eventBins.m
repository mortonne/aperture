function [ev2, bine, events2] = eventBins(ev1, params, events1)

if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'field', '',  'eventbinlabels', '');

if ~exist('events1', 'var')
  load(ev1.file);
  events1 = events;
end

ev2 = ev1;
if strcmp(params.field, 'overall')
  vec = ones(1, length(events1));
elseif isfield(events1, params.field)
  vec = getStructField(events1, params.field);
else
  for e=1:length(events1)
    bine{e} = e;
  end
  events2 = events1;
  return
end

% find the events corresponding to each condition
vals = unique(vec);
ev2.len = length(vals);
for j=1:length(vals)
  if iscell(vals)
    events2(j).value = vals{j};
    if ~isempty(params.eventbinlabels)
      events2(j).type = params.eventbinlabels{j};
    else
      events2(j).type = [params.field ' ' vals{j}];
    end
    bine{j} = strcmp(vec, vals{j});
  else
    events2(j).value = vals(j);
    if ~isempty(params.eventbinlabels)
      events2(j).type = params.eventbinlabels{j};
    else
      events2(j).type = [params.field ' ' num2str(vals(j))];
    end
    bine{j} = vec==vals(j);
  end
end
