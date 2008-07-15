function exp = addEvents(exp, eventsFile, resDir, evname)
%
%ADDEVENTS   Import events into an exp struct.
%   EXP = ADDEVENTS(EXP) loads the events saved in each session
%   directory in a file named 'events.mat', and concatenates
%   them to create one events struct for each subject.  Each
%   subject in EXP has a new ev object added named 'events'.
%
%   ADDEVENTS prepares each subject's events for analysis in
%   other scripts.
%
%   EXP = ADDEVENTS(EXP,EVENTSFILE,RESDIR,EVNAME) loads the
%   events in each session directory using the relative path
%   EVENTSFILE, saves in RESDIR/events, and names the new ev
%   object EVNAME.
%

if ~exist('evname', 'var')
  evname = 'events';
end
if ~exist('resDir', 'var')
  resDir = exp.resDir;
end
if ~exist(fullfile(resDir, 'events'), 'dir')
  mkdir(fullfile(resDir, 'events'));
end
if ~exist('eventsFile', 'var')
  eventsFile = 'events.mat';
end

for subj=exp.subj
  fprintf('Concatenating events for %s...\n', subj.id);
  
  ev.name = evname;
  ev.file = fullfile(resDir, 'events', [evname '_' subj.id '.mat']);
  
  subj_events = [];
  for sess=subj.sess
    load(fullfile(sess.dir, eventsFile));
    if ~isfield(events, 'eegfile')
      [events(:).eegfile] = deal('');
      [events(:).eegoffset] = deal([]);
      [events(:).artifactMS] = deal([]);
    end
    
    subj_events = [subj_events(:); events(:)]';
  end
  if isempty(unique(getStructField(events, 'eegfile')))
    events = rmfield(events, 'eegfile');
    events = rmfield(events, 'eegoffset');
    events = rmfield(events, 'artifactMS');
  end
  
  events = subj_events;
  ev.len = length(events);
  save(ev.file, 'events');

  exp = update_exp(exp, 'subj', subj.id, 'ev', ev);
end
