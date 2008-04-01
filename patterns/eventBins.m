function [ev2, bine, events2] = eventBins(ev1, params, events1)

if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'field', '');

if ~exist('events1', 'var')
  load(ev1.file);
end

if strcmp(params.field, 'overall')
  vec = ones(1, length(events1));
elseif isfield(events1, params.field)
  vec = getStructField(events1, params.field);
else
  ev2 = ev1;
  for e=1:length(events1)
    bine{e} = e;
  end
  events2 = events1;
  return
end

% find the events corresponding to each condition
vals = unique(vec);
ev2.length = length(vals);
for j=1:length(vals)
  if iscell(vals)
    events2(j).value = vals{j};
    events2(j).type = [params.field ' ' vals{j}];
    bine{j} = strcmp(vec, vals{j});
  else
    events2(j).value = vals(j);
    events2(j).type = [params.field ' ' num2str(vals(j))];
    bine{j} = vec==vals(j);
  end
end

