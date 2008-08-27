function events = catallevents(exp,evname)
%events = catallevents(exp,evname)

if ~exist('evname','var')
  evname = 'events';
end

fprintf('\nConcatenating events for all subjects...\n')
allev = [];
for subj=exp.subj
  fprintf('%s ', subj.id)

  ev = getobj(subj,'ev',evname);
  load(ev.file);
  events = events(:)';
  
  allev = [allev events];
end
events = allev;
fprintf('\n')
