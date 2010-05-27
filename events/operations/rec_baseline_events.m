function events = rec_baseline_events(events, rec_duration, varargin)
%REC_BASELINE_EVENTS   Add events to use for baseline in recall periods.
%
%  events = rec_baseline_events(events, rec_duration, ...)
%
%  INPUTS:
%        events:  an events structure. Assumed to have fields:
%                  type      - Start of recall periods have type
%                              "REC_START"
%                  mstime    - experiment time in milliseconds
%                  rectime   - time since start of recall in ms
%                  eegoffset - sample number in the EEG file
%                  eegfile   - path to the EEG file
%
%  rec_duration:  duration of each recall period in ms. May be a scalar
%                 (if all durations are the same) or a vector of length
%                 number of recall periods (if durations vary)
%
%  OUTPUTS:
%        events:  events with added REC_BASE events.
%
%  PARAMS:
%   pre          - time before each vocalization event to exclude.
%                  (1000)
%   post         - time after each vocalization onset to exclude. (1000)
%   duration     - duration of each random free epoch. (200)
%   start_buffer - buffer after start of recall period to exclude. (500)

% options
defaults.pre = 1000;
defaults.post = 1000;
defaults.duration = 200;
defaults.start_buffer = 500;
params = propval(varargin, defaults);

% get the time of each event
times = [events.mstime];

% make sure the mstime field is valid across sessions
if ~issorted(times)
  error(['Event times are not in order. This could indicate overlap ' ...
         'between session times.'])
end

% get recall period start times
rec_start_events = events(strcmp({events.type}, 'REC_START'));

% NWM: attempt to deal with multiple recall durations
if isscalar(rec_duration)
  rec_duration = repmat(rec_duration, length(rec_start_events), 1);
end

base_events = [];
for i = 1:length(rec_start_events)
  rec_start = rec_start_events(i).mstime;
  rec_start_samp = rec_start_events(i).eegoffset;
  
  % times of all events during this recall period (assuming they are
  % disruptive events of some type, not suitable for baseline)
  %rec_ind = rec_start < times & times <= rec_start + rec_duration;
  % NWM: attempt to deal with multiple recall durations
  rec_ind = rec_start < times & times <= rec_start + rec_duration(i);
  if ~any(rec_ind)
    continue
  end
  
  voc_times = times(rec_ind);
  
  % get EEG files for this recall period
  eeg_files = unique({events(rec_ind).eegfile});
  if length(eeg_files) > 1
    warning('Recall period split over multiple EEG files. Skipping...')
    continue
  end
  
  % assume same samplerate regardless
  samplerate = GetRateAndFormat(rec_start_events(i));
  
  % find free time between events
  p = rmfield(params, {'duration', 'start_buffer'});
  p.start = rec_start + params.start_buffer;
  p.finish = rec_start + rec_duration(i);
  free = free_epochs(voc_times, params.duration, p);

  % for a proper baseline, we want the sample to be the same size as
  % the number of recall events, so we can estimate the variance of the
  % data we want to z-transform. If we have more than we need, take a
  % random sample
  n_trial_events = length(voc_times);
  n_free = length(free);
  if n_free < n_trial_events
    fprintf('Warning: only found %d baseline epochs for %d recall events.\n', ...
            n_free, n_trial_events)
  end
  
  if n_free == 0
    continue
  elseif n_free <= n_trial_events
    rand_free_times = free;
  else
    rand_free_times = sort(randsample(free, n_trial_events));
  end
  
  % use apply_event_bins to get fields that are the same throughout
  % the trial
  free_events = apply_event_bins(events(rec_ind), 1:nnz(rec_ind));
  free_events = repmat(free_events, 1, length(rand_free_times));
  
  % set the type code
  [free_events.type] = deal('REC_BASE');
  
  % experiment time
  c = num2cell(rand_free_times);    
  [free_events.mstime] = c{:};
  
  % recall period time
  c = num2cell(rand_free_times - rec_start);
  [free_events.rectime] = c{:};
  
  % EEG sample
  rand_free_samp = rec_start_samp + ...
      ms2samp(rand_free_times, samplerate, rec_start);
  c = num2cell(rand_free_samp);
  [free_events.eegoffset] = c{:};
  
  base_events = cat_structs(base_events, free_events);
end

% concatenate and sort
events = sort_events(cat_structs(events, base_events));

