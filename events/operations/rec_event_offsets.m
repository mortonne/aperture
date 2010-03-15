function events = rec_event_offsets(events, rec_duration, start_buffer)
%REC_EVENT_OFFSETS   Add event offsets to recall events.
%
%  events = rec_event_offsets(events, rec_duration, start_buffer)
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
%  start_buffer:  buffer to add after each recall start event.
%
%  OUTPUTS:
%        events:  events structure with added preoffset field.

if nargin < 3
  start_buffer = 0;
end

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

for rec_start = rec_starts
  % times of all events during this recall period (assuming they are
  % disruptive events of some type, not suitable for baseline)
  rec_ind = rec_start < times & times <= rec_start + rec_duration;
  if ~any(rec_ind)
    continue
  end
  
  voc_times = times(rec_ind);
  
  % find free time between events
  offsets = free_offsets(voc_times, rec_start + start_buffer);
  
  % add to new field
  c = num2cell(offsets);
  [events(rec_ind).preoffset] = c{:};
end
