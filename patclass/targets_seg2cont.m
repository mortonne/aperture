function cont_targets = targets_seg2cont(targets, times, samplerate, window, ...
                                         varargin)
%TARGETS_SEG2CONT   Convert segmented targets to continous format.
%
%  cont_targets = targets_seg2cont(targets, times, samplerate, window, ...)
%
%  INPUTS:
%     targets:  [conditions X events] logical array of targets.
%
%       times:  vector of length events giving the starting time of each
%               event in ms.
%
%  samplerate:  rate at which to sample the condition labels, in Hz.
%
%      window:  the window around the start of each event to mark with
%               that condition in ms, specified as [start end].
%
%  OUTPUTS:
%  cont_targets:  logical array of continuous targets. Size depends on
%                 the start and end times, as well as the samplerate.
%
%  PARAMS:
%   start    - start in ms of the period to map targets into. (0)
%   finish   - end in ms of the period to map targets into.
%              (max(times) + window(2))
%   priority - indicates how to deal with overlap between events.
%              Currently the only supported rule is 'early'; that is,
%              earlier events take priority over later events when there
%              is overlap. ('early')

% sanity checks
if size(targets, 2) ~= length(times)
  error('Number of events must match for targets and times')
end

% options
defaults.start = 0;
defaults.finish = max(times) + window(2);
defaults.priority = 'early';
params = propval(varargin, defaults);

% initialize the continuous targets
[n_conds, n_events] = size(targets);
duration = params.finish - params.start;
n_samples = ceil(duration * (samplerate / 1000));
cont_targets = false(n_conds, n_samples);

if isempty(targets)
  % nothing to translate; return all false
  return
end

if ~strcmp(params.priority, 'early')
  error('Only early priority is currently supported.')
end

% make sure targets are in temporal order
[times, i] = sort(times);
targets = targets(:,i);

% define the time bins
timestep = 1000 / samplerate;
start_times = params.start:timestep:params.finish;
if start_times(end) == params.finish
  start_times(end) = [];
end
finish_times = params.start + timestep:timestep:params.finish;

% write events in reverse order so that earlier events take priority
for i = n_events:-1:1
  % include a time bin as part of the event if is anywhere inside it
  window_start = find(start_times <= times(i) + window(1), 1, 'last');
  if isempty(window_start)
    window_start = 1;
  end
  window_finish = find(finish_times >= times(i) + window(2), 1, 'first');
  if isempty(window_finish)
    window_finish = n_events;
  end
  
  % map into continuous space
  window_duration = window_finish - window_start + 1;
  if window_duration < 1
    continue
  elseif window_duration == 1
    cont_targets(:,window_start) = targets(:,i);
  else
    cont_targets(:,window_start:window_finish) = repmat(targets(:,i), ...
                                                        1, window_duration);
  end
end

