function exp = addEvents(exp, eventsFile, resDir, evname)
%exp = addEvents(exp, eventsFile)

for s=1:length(exp.subj)
  ev.name = evname;
  ev.file = fullfile(resDir, 'events', [evnamme '_' exp.subj(s).id '.mat']);
  
  events = [];
  for n=1:length(exp.subj(s).sess)
    sess_events = load(fullfile(exp.subj(s).sess(n).dir, eventsFile));
    events = concat(events(:), sess_events(:))';
  end
  
  save(ev.file, 'events');
  
  load(exp.file);
  exp = setobj(exp, 'ev', ev);
  save(exp.file);
end
