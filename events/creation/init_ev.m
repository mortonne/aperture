function ev = init_ev(name,source,file,len)
%INIT_EV   Initialize an ev object to hold events metadata.
%   EV = INIT_EV(NAME,SOURCE,FILE,LEN) creates structure EV that
%   holds basic info about an events struct, including
%   the path to the .mat file where the events struct is
%   saved.
%
%   Fields:
%     'name'    string identifier of the object
%     'source'  string indicating the source of the events,
%               or a cell array of strings if there are
%               multiple sources
%     'file'    path to .mat file containing events
%     'len'     length of the events structure
%

if ~exist('len','var')
  len = NaN;
end
if ~exist('file','var')
  file = 'events.mat';
end
if ~exist('source','var')
  source = '';
end
if ~exist('name','var')
  name = 'events';
end

% create ev
ev = struct('name',name, 'source','', 'file',file, 'len',len);
ev.source = source;
