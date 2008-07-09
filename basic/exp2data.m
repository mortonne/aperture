function data = exp2data(exp,dataFcnHandle, evname)

if ~exist('dataFcnHandle','var')
  dataFcnHandle = @extract_data;
end
if ~exist('evname','var')
  evname = 'events';
end

% create a data struct with all subjects
data = [];
for s=1:length(exp.subj)
  ev = getobj(exp.subj(s), 'ev', evname);
  load(ev.file);
  
  subj_data = dataFcnHandle(events);
  
  data = concatData(data, subj_data);
end
