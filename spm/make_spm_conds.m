function [onsets_cell, durations_cell] = make_spm_conds(events, ...
                                                  filts, durations, run)

if nargin == 4
  % filter to just get the run being examined
  events = events([events.run] == run);
end

n_conds = length(filts);
onsets_cell = cell(1, n_conds);
durations_cell = cell(1, n_conds);
for i = 1:n_conds
  % get events that match the filter
  ind = inStruct(events, filts{i});
  
  % get onset times in seconds
  cond_onsets = [events(ind).runtime] / 1000;
  
  if length(durations) == 1
    cond_durations = repmat(durations, 1, length(cond_onsets));
  elseif length(durations) == n_conds
    cond_durations = repmat(durations(i), 1, length(cond_onsets));
  end
  
  onsets_cell{i} = cond_onsets;
  durations_cell{i} = cond_durations;
end

