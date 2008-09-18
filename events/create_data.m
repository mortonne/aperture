function [ev,err] = create_data(ev,params,resdir)
%CREATE_DATA   Create a data struct from an events struct.
%   EV = CREATE_DATA(EV,DATAFCN,RESDIR) creates a data structure
%   from the events structure saved in EV, using DATAFCN. The
%   resulting data structure is saved in RESDIR/data.mat; the
%   path to the data structure is stored in ev.datafile.
%

if ~exist('resdir','var')
  [dir,filename] = fileparts(ev.file);
  resdir = fullfile(fileparts(fileparts(dir)), ev.name);
end
if ~exist('params','var')
  params = struct;
end

params = structDefaults(params, 'datafcn',@FRdata, 'datafcninput',{});

ev.datafile = fullfile(resdir,'data',sprintf('data_%s.mat',ev.source));

% check input files
err = prepFiles(ev.file, ev.datafile, params);
if err
  return
end

load(ev.file);

% create the data struct
fprintf('creating data struct using %s...', func2str(params.datafcn))
data = params.datafcn(events,params.datafcninput{:});

save(ev.datafile,'data')
fprintf('saved.')
