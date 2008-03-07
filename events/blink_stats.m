function blink_stats(exp, params)
%
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

params = structDefaults(params, 'evname', 'events',  'eventFilter', '',  'windowEnd', 2000);

for s=1:length(exp.subj)
  fprintf('%s:\n', exp.subj(s).id);
  
  % load this subject's events
  ev = getobj(exp.subj(s), 'ev', params.evname);
  load(ev.file);
  
  % run filter if specified
  events = filterStruct(events, params.eventFilter);
  
  sessions = unique(getStructField(events, 'session'));
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
    fprintf('%s-%d\t%f\n', exp.subj(s).id, sessions(n), percent_art);
  end
  fprintf('\n');
end
