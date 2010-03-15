function offsets = free_offsets(times, duration, start)
%FREE_OFFSETS   Free time between an event and the prior event.
%
%  offsets = free_offsets(times, duration, start)
%
%  INPUTS:
%     times:  [trials X events] matrix of times.
%
%  duration:  duration of each event. Default is 0. If the start of an
%             event is before the end of the previous event, its offset
%             will be 0.
%  
%     start:  optional. Start time of interest. Returned offsets will be
%             the difference between the time and the previous or the
%             time and the start time, whichever is smaller. If a time
%             is before start, its offset is 0. May be a scalar or a
%             vector of length [trials], where start(i) gives the start
%             time of row i in times.
%
%  OUTPUTS:
%   offsets:  free time before each event.
%
%  EXAMPLES:
%  >> times = [5 8 15 NaN NaN
%              2 3 9 17 NaN];
%  >> offsets = free_offsets(times)
%  offsets =
%   NaN    -3    -7   NaN   NaN
%   NaN    -1    -6    -8   NaN
%
%  >> offsets = free_offsets(times, 0, 3)
%  offsets =
%    -2    -3    -7   NaN   NaN
%     0     0    -6    -8   NaN
%
%  >> offsets = free_offsets(times, 4, 3)
%    -2     0    -3   NaN   NaN
%     0     0    -2    -4   NaN

if nargin < 3
  start = [];
  if nargin < 2
    duration = 0;
  end
end

[n_trials, n_recalls] = size(times);
offsets = NaN(n_trials, n_recalls);
if isempty(offsets)
  return
end

for i=1:n_trials
  % remove invalid times
  trial_times = times(i,:);
  trial_times(~(trial_times > 0)) = NaN;
  
  % get difference between start of each event and end of previous event
  post_times = trial_times + duration;
  irt = trial_times(2:end) - post_times(1:end-1);
  
  if ~isempty(start)
    if length(start) == n_trials
      rel_times = trial_times - start(i);
    else
      rel_times = trial_times - start;
    end
    
    % offset is smaller of IRT and time since start
    irt = min(irt, rel_times(2:end));
    
    % offset of first item is time since start
    offsets(i,:) = [rel_times(1) irt];
  else
    % just use IRT
    offsets(i,2:end) = irt;
  end
end

% if negative, there is no free space
offsets = -offsets;
offsets(offsets > 0) = 0;

