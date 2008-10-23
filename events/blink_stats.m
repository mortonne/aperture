function [ev,status] = blink_stats(ev, params)
%BLINK_STATS   Get information from an events struct about artifacts.
%   EV = BLINK_STATS(EV,PARAMS) loads the events from EV and calculates
%   statistics having to do with artifacts.  The returned EV has a new
%   field, "blinks," that gives the percentage of events with artifacts.
%
%   Params:
%     'eventFilter' Filter to apply to the events before calculating
%                   blink percentage
%     'windowEnd'   Can either be a scalar denoting a time in milliseconds
%                   after each event to look for artifacts, or a string
%                   containing the name of a field that has a millisecond
%                   value for each event
%
%   Example:
%    To only count blinks that happened before the partcipant reacted:
%    ev = blink_stats(ev,struct('windowEnd','rt'));
%

if ~exist('params', 'var')
  params = [];
end

params = structDefaults(params, 'eventFilter','', 'windowEnd',2000, 'verbose',0);
status = 0;

load(ev.file);

% run filter if specified
events = filterStruct(events, params.eventFilter);

if isempty(events)
  error('Events struct is empty after filtering with: ''%s''', params.eventFilter)
  err = 1;
  return
end

fprintf('calculating blink stats...')
sessions = unique(getStructField(events, 'session'));
ev.blinks = NaN(length(sessions),1);
for n=1:length(sessions)
  sess_events = filterStruct(events, 'session==varargin{1}', sessions(n));

  art = getStructField(sess_events, 'artifactMS');
  if all(isnan(art))
    warning('session %d events have no artifact info. Skipping...',sessions(n));
    continue
  end

  if isstr(params.windowEnd)
    % use a dynamic window (reaction time, for example)
    windEnd = getStructField(sess_events, params.windowEnd);
    art_ev = sum(art>0 & art<windEnd);
    else
    % get number of events with artifacts from 1ms to (windowEnd)ms
    art_ev = sum(art>0 & art<params.windowEnd);
  end
  percent_art = art_ev/length(sess_events);

  if params.verbose
    % print percentage
    fprintf('\nSession %d\t%.4f', sessions(n), percent_art);
  end

  % add to the ev object
  ev.blinks(n) = percent_art;
end
