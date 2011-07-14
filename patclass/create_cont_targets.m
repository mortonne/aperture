function targets = create_cont_targets(trial_events, seg_events, bin_defs, ...
                                       trial_defs, trial_duration, ...
                                       samplerate, time_field, window, varargin)
%CREATE_CONT_TARGETS   Create continuous targets for multiple trials.
%
%  targets = create_cont_targets(trial_events, seg_events, bin_defs,
%                                trial_defs, trial_duration, samplerate,
%                                time_field, window)
%
%  INPUTS:
%    trial_events:  events struct with one element for each trial. Must
%                   have a field with the time in ms.
%
%      seg_events:  events struct with one element for each event. Must
%                   have a field with the time in ms.
%
%        bin_defs:  input to make_event_index for creating targets.
%
%      trial_defs:  input to make_event_index for defining different
%                   trials. Must work with both trial_events and
%                   seg_events.
%
%  trial_duration:  duration of each trial in ms.
%
%      samplerate:  rate at which to sample the continous targets in Hz.
%
%      time_field:  name of the events field containing time in ms.
%
%          window:  time before and after each event to mark, as
%                   [start end], in ms.
%
%  OUTPUTS:
%  targets:  [conditions X samples] matrix defining the condition of
%            each time bin.

% make one index with all events
[index, levels] = make_event_index(cat_structs(trial_events, seg_events), ...
                                   trial_defs);
trial_index = index(1:length(trial_events));
seg_index = index(length(trial_events) + 1:end);

% create segmented targets
seg_targets = create_targets(seg_events, bin_defs);

uindex = nanunique(index);
targets = [];
for i = 1:length(uindex)
  start_event = trial_events(find(trial_index == uindex(i), 1));
  if isempty(start_event)
    % no trial start event, so this trial is excluded from the
    % trial_events and should also be excluded from the targets
    continue
  end
  
  trial_seg = seg_events(seg_index == uindex(i));
  start_time = start_event.(time_field);

  % get segmented targets
  if isempty(trial_seg)
    % hack to deal with cases where there are no segmented events for
    % a given trial; create a dummy event with no condition label
    n_cond = size(seg_targets, 1);
    trial_seg_targets = false(n_cond, 1);
    times = start_time;
  else
    % get the targets and times for this trial
    trial_seg_targets = seg_targets(:,seg_index == uindex(i));
    times = [trial_seg.(time_field)];
  end

  % map to continuous targets
  cont_targets = targets_seg2cont(trial_seg_targets, times, ...
                                  samplerate, window, ...
                                  'start', start_time, ...
                                  'finish', start_time + trial_duration);
  
  % add to the complete set of targets
  targets = [targets cont_targets];
end

