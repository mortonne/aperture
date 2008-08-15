function ev = blink_stats(ev, params)
%BLINK_STATS - get info from events structs about blink artifacts
%
% FUNCTION: blink_stats(exp, params)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - optional fields: evname (specify which ev object
%                 to use; default is 'events'), eventFilter (specify subset of
%                 events to use), windowEnd (ms time to end window
%                 in which to look for artifacts, or string
%                 specifying a field containing an ms time to use
%                 as the end window)
%
% OUTPUT: printed blink stats for each subject
% 

if ~exist('params', 'var')
  params = [];
end

params = structDefaults(params, 'evname', 'events',  'eventFilter', '',  'windowEnd', 2000);

load(ev.file);

% run filter if specified
events = filterStruct(events, params.eventFilter);

sessions = unique(getStructField(events, 'session'));
ev.blinks = NaN(length(sessions),1);
for n=1:length(sessions)
  sess_events = filterStruct(events, 'session==varargin{1}', sessions(n));

  art = getStructField(sess_events, 'artifactMS');

  if isstr(params.windowEnd)
    % use a dynamic window (reaction time, for example)
    windEnd = getStructField(sess_events, params.windowEnd);
    art_ev = sum(art>0 & art<windEnd);
    else
    % get number of events with artifacts from 1ms to (windowEnd)ms
    art_ev = sum(art>0 & art<params.windowEnd);
  end
  percent_art = art_ev/length(sess_events);

  % print percentage
  fprintf('%d\t%f\n', sessions(n), percent_art);

  % add to the ev object
  ev.blinks(n) = percent_art;
end
