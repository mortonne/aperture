function fig = init_fig(name, file, source)
%INIT_FIG   Initialize a struct to hold metadata about figures.
%   FIG = INIT_FIG() initializes a fig with default values.
%
%   FIG = INIT_FIG(NAME,FIGTYPE,FILE,PARAMS,TITLE) initializes a fig
%   object with fields NAME, FIGTYPE, FILE, PARAMS, and TITLE.
%
%   Fields:
%     'name'    string identifier used to reference the fig object
%     'file'    string or cell array of strings holding filenames
%               of figures
%     'source'  name of the parent object

if ~exist('name','var')
  name = '';
end
if ~exist('file','var')
  file = '';
end
if ~exist('source','var')
  source = '';
end

if iscell(file) & isempty(file)
  file = {''};
end

% create the fig structure
fig = struct('name',name, 'file','', 'source',source);

% now add the file cell array
fig.file = file;
