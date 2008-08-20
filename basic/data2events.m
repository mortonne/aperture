function events = data2events(data)
%DATA2EVENTS
%   EVENTS = DATA2EVENTS(DATA)

fnames = fieldnames(data);
for i=1:length(fnames)
  
  % transpose and vectorize to get back in events order
  field = data.(fnames{i})';
  vec = field(:);
  
  % fill in the events struct
  for j=1:length(vec)
    if iscell(vec)
      events(j).(fnames{i}) = vec{j};
      else
      events(j).(fnames{i}) = vec(j);
    end
  end
end
