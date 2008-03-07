function exp = addEvents(exp, eventsFile, resDir, evname)
%exp = addEvents(exp, eventsFile)

if ~exist(fullfile(resDir, 'events'), 'dir')
  mkdir(fullfile(resDir, 'events'));
end

for s=1:length(exp.subj)
  
  ev.name = evname;
  ev.file = fullfile(resDir, 'events', [evname '_' exp.subj(s).id '.mat']);
  
  subj_events = [];
  for n=1:length(exp.subj(s).sess)
    load(fullfile(exp.subj(s).sess(n).dir, eventsFile));
    subj_events = [subj_events(:); events(:)]';
  end
  
  events = subj_events;
  ev.len = length(events);
  save(ev.file, 'events');
  
  
  if ~isfield(exp.subj(s), 'ev')
    exp.subj(s).ev = [];
  end

  exp.subj(s) = setobj(exp.subj(s), 'ev', ev);
end
save(exp.file);
