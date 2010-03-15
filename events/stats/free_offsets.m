function offsets = free_offsets(times, start)
%FREE_OFFSETS   Free time between an event and the prior event.
%
%  offsets = free_offsets(times, start)
%
%  INPUTS:
%    times:  [trials X events] matrix of times.
%
%    start:  optional. Start time of interest. Returned offsets will be
%            the difference between the time and the previous or the
%            time and the start time, whichever is smaller. If a time
%            is before start, its offset is 0. May be a scalar or a
%            vector of length [trials], where start(i) gives the start
%            time of row i in times.
%
%  OUTPUTS:
%  offsets:  free time before each event.
%
%  EXAMPLES:
%  >> times = [5 8 15 NaN NaN
%              2 3 9 17 NaN];
%  >> offsets = free_offsets(times, 3)
%  offsets =
%     2     3     7   NaN   NaN
%     0     0     6     8   NaN
%
%  >> offsets = free_offsets(times)
%  offsets =
%   NaN     3     7   NaN   NaN
%   NaN     1     6     8   NaN

if nargin < 2
  start = [];
end

[n_trials, n_recalls] = size(times);
offsets = NaN(n_trials, n_recalls);
if isempty(offsets)
  return
end

for i=1:n_trials
  % get IRTs for all valid times
  mask = times(i,:) > 0;
  irt = transitions(times(i,:), mask, mask, @distance, 1, struct);
  
  if ~isempty(start)
    if length(start) == n_trials
      rel_times = times(i,:) - start(i);
    else
      rel_times = times(i,:) - start;
    end
    
    % get time since start; if negative, set to 0
    rel_times(rel_times < 0) = 0;
    
    % offset is smaller of IRT and time since start
    irt = min(irt, rel_times(2:end));
    
    % offset of first item is time since start
    offsets(i,:) = [rel_times(1) irt];
  else
    % just use IRT
    offsets(i,2:end) = irt;
  end
  
  if any(offsets(i,:) < 0)
    error('Input times are out of order.')
  end
end

