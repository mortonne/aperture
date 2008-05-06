function exp = addEvents(exp, eventsFile, resDir, evname)
%exp = addEvents(exp, eventsFile, resDir, evname)

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

for s=1:length(exp.subj)
  fprintf('Concatenating events for %s...\n', exp.subj(s).id);
  
  ev.name = evname;
  ev.file = fullfile(resDir, 'events', [evname '_' exp.subj(s).id '.mat']);
  
  subj_events = [];
  for n=1:length(exp.subj(s).sess)
    load(fullfile(exp.subj(s).sess(n).dir, eventsFile));
    if ~isfield(events, 'eegfile')
      keyboard
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
  
  if ~isfield(exp.subj(s), 'ev')
    exp.subj(s).ev = [];
  end

  exp = update_exp(exp, 'subj', exp.subj(s).id, 'ev', ev);
end
