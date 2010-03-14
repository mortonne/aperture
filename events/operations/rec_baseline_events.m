function events = rec_baseline_events(events, rec_duration, varargin)
%REC_BASELINE_EVENTS   Add events to use for baseline in recall periods.
%
%  events = rec_baseline_events(events, rec_duration, ...)
%
%  INPUTS:
%        events:  an events structure. Must have fields:
%                  type      - all vocalization events have type
%                              REC_WORD. Recall start is REC_START
%                  session   - numeric session index
%                  mstime    - experiment time in milliseconds
%                  rectime   - time since start of recall in ms
%                  eegoffset - sample number in the EEG file
%                  eegfile   - path to the EEG file
%
%  rec_duration:  duration of the recall period in ms.
%
%  OUTPUTS:
%        events:  events with added REC_BASE events.
%
%  PARAMS:
%   pre      - time before each vocalization event to exclude. (1000)
%   post     - time after each vocalization onset to exclude. (1000)
%   duration - duration of each random free epoch. (200)

% options
defaults.pre = 1000;
defaults.post = 1000;
defaults.duration = 200;
params = propval(varargin, defaults);

samplerate = GetRateAndFormat(events(1));
base_events = [];
sessions = unique([events.session]);
for session = sessions
  sess_events = events([events.session] == session);
  
  n_rec_events = nnz(strcmp({sess_events.type}, 'REC_WORD'));
  if n_rec_events == 0
    % no recall events to get baseline for
    fprintf('no recall events in session %d. skipping...\n', session)
    continue
  end
  
  % get recall period start times
  rec_start_events = sess_events(strcmp({sess_events.type}, 'REC_START'));
  sess_times = [sess_events.mstime];
  
  for i = 1:length(rec_start_events)
    rec_start = rec_start_events(i).mstime;
    rec_start_samp = rec_start_events(i).eegoffset;
    
    % times of all events during this recall period (assuming they are
    % disruptive events of some type, not suitable for baseline). If
    % they are OK for baseline, why are you using this script? You're
    % so stupid!
    rec_ind = rec_start < sess_times & sess_times <= rec_start + rec_duration;
    voc_times = sess_times(rec_ind);
    
    % find free time between events
    p = rmfield(params, 'duration');
    p.start = rec_start;
    p.finish = rec_start + rec_duration;
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
    free_events = apply_event_bins(sess_events(rec_ind), 1:nnz(rec_ind));
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
end

% concatenate and sort
events = sort_events(cat_structs(events, base_events));

