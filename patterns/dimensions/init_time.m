function time = init_time(MSvals, labels)

if ~exist('MSvals', 'var')
  time = struct('MSvals', [],  'avg', [],  'label', '');
  return
end

if ~exist('labels', 'var')
  labels = {};
end

for t=1:length(MSvals)
  time(t).MSvals = MSvals(t);
  time(t).avg = MSvals(t);
  if ~isempty(labels)
    time(t).label = labels{t};
  else
    time(t).label = sprintf('%d ms', MSvals(t));
  end
end
