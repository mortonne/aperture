function targets = index2targets(index)
%INDEX2TARGETS   Convert an index vector to a targets matrix.
%
%  targets = index2targets(index)

n_events = length(index);
n_conds = max(index);
targets = false(n_conds, n_events);
for i = 1:n_events
  targets(index(i),i) = true;
end

