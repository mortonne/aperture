function events = catallevents(exp,evname)

if ~exist('evname','var')
  evname = 'events';
end

allev = [];
for subj=exp.subj
  ev = getobj(subj,'ev',evname);
  load(ev.file);
  events = events(:)';
  
  allev(end+1) = events;
end
events = allev;
