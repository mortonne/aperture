function events = rec_event_offsets(events, rec_duration, varargin)
%REC_EVENT_OFFSETS   Add event offsets to recall events.
%
%  events = rec_event_offsets(events, rec_duration, ...)
%
%  INPUTS:
%        events:  an events structure. Assumed to have fields:
%                  type      - Start of recall periods have type
%                              "REC_START"
%                  mstime    - experiment time in milliseconds
%
%  rec_duration:  duration of each recall period in ms. Must be the
%                 same for all recall periods.
%
%  OUTPUTS:
%        events:  events structure with added preoffset field.
%
%  PARAMS:
%   start_buffer - buffer to add after each recall start event. (0)
%   voc_duration - time to exclude after each vocalization. (1000)

defaults.start_buffer = 0;
defaults.voc_duration = 1000;
defaults.exclude_overlap = false;
params = propval(varargin, defaults);

% make sure we have a row vector
if size(events, 1) > 1
  events = events';
end

% get the time of each event
[events.preoffset] = deal(NaN);
times = [events.mstime];

% make sure the mstime field is valid across sessions
if ~issorted(times)
  error(['Event times are not in order. This could indicate overlap ' ...
         'between session times.'])
end

% get recall period start times
rec_starts = [events(strcmp({events.type}, 'REC_START')).mstime];

for i = 1:length(rec_starts)
  rec_start = rec_starts(i);
  
  % times of all events during this recall period (assuming they are
  % disruptive events of some type, not suitable for baseline)
  if params.exclude_overlap && i < length(rec_starts)
    % get either the expected recall end or the start of the next recall
    % period, whichever ends first
    time_to_next = rec_starts(i + 1) - rec_start;
    max_rec_time = min([rec_duration time_to_next]);
  else
    max_rec_time = rec_duration;
  end
  
  % get all times in the recall window
  rec_ind = rec_start < times & times < rec_start + max_rec_time;
  if ~any(rec_ind)
    continue
  end
  voc_times = times(rec_ind);  

  % check for overlap
  if i < length(rec_starts) && any(voc_times > rec_starts(i + 1))
    error('Recall period %d overlaps with next recall period.', i)
  end
  
  % find free time between events
  offsets = free_offsets(voc_times, params.voc_duration, ...
                         rec_start + params.start_buffer);
  
  % add to new field
  c = num2cell(offsets);
  [events(rec_ind).preoffset] = c{:};
end
