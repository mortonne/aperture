function [data,exp] = exp2data(exp,dataFcnHandle,evname,datafile)

if ~exist('dataFcnHandle','var')
  dataFcnHandle = @extract_data;
end
if ~exist('evname','var')
  evname = 'events';
end
if ~exist('datafile','var')
  datafile = fullfile(exp.resDir, 'data.mat');
end

% create a data struct with all subjects
data = [];
for s=1:length(exp.subj)
  ev = getobj(exp.subj(s), 'ev', evname);
  load(ev.file);
  
  subj_data = dataFcnHandle(events);
  
  data = concatData(data, subj_data);
end

% save the full data struct
exp.datafile = datafile;
exp = update_exp(exp);

save(exp.datafile, 'data');
