function epoch_times = free_epochs(times, duration, varargin)
%FREE_EPOCHS   Given times of events, find epochs where nothing is happening.
%
%  epoch_times = free_epochs(times, duration, ...)
%
%  INPUTS:
%        times:  matrix of times of events, one row for each trial.
%
%     duration:  duration of created free epochs.
%
%  OUTPUTS:
%  epoch_times:  start times of found free epochs. If the number of free
%                epochs is different for different trials, rows will be
%                padded with NaNs.
%
%  PARAMS:
%   pre    - time before each event to exclude. (0)
%   post   - time after each event to exclude. (0)
%   start  - if specified, all returned epochs will begin after this
%            time. ([])
%   finish - if specified, all returned epochs will end before this
%            time. ([])
%   mask   - logical array the same size as times, specifying times to
%            mark as filled. Default is to include all positive times.
%
%  EXAMPLES:
%  >> times = [5 8 15 NaN NaN
%              2 3 9 17 NaN];
%  >> epoch_times = free_epochs(times, 2, 'pre', 2, 'post', 1)
%  epoch_times =
%   9    11   NaN
%   4    10    12
%
%  >> params = struct('pre', 2, 'post', 1, 'start', 3, 'finish', 18);
%  >> epoch_times = free_epochs(times, 2, params)
%  epoch_times =
%   9    11    16
%   4    10    12

% set options
defaults.pre = 0;
defaults.post = 0;
defaults.start = [];
defaults.finish = [];
defaults.mask = times > 0;
params = propval(varargin, defaults);

n_trials = size(times, 1);
epoch_times = [];
for i = 1:n_trials
  trial_times = times(i, params.mask(i,:));
  
  % get start and end of each event to avoid
  pre_times = trial_times - params.pre;
  post_times = trial_times + params.post;
  
  % optionally add start and end times
  if ~isempty(params.start)
    % start has no duration, so pre=post 
    pre_times = [params.start pre_times];
    post_times = [params.start post_times];
    
    % exclude events that finish before the start time
    before_start = post_times < params.start;
    pre_times = pre_times(~before_start);
    post_times = post_times(~before_start);
  end
  if ~isempty(params.finish)
    % finish has no duration, so pre=post 
    pre_times = [pre_times params.finish];
    post_times = [post_times params.finish];
    
    % exclude events that begin after the finish time
    after_finish = pre_times > params.finish;
    pre_times = pre_times(~after_finish);
    post_times = post_times(~after_finish);
  end
  
  % get length of each interval
  interval_durations = pre_times(2:end) - post_times(1:end-1);
  
  free_intervals = find(interval_durations >= duration);
  trial_epoch_times = [];
  for interval = free_intervals
    % first time to include
    start = post_times(interval);
    
    % last possible time to include while avoiding events
    finish = pre_times(interval + 1) - duration;
        
    % find all start times matching criteria
    interval_epoch_times = start:duration:finish;
    trial_epoch_times = [trial_epoch_times interval_epoch_times];
  end

  % so row index keeps meaning, even if no free periods this trial
  if isempty(trial_epoch_times)
    trial_epoch_times = NaN;
  end
  
  epoch_times = padcat(1, NaN, epoch_times, trial_epoch_times);
end


