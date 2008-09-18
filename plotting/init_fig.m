function fig = init_fig(name, figtype, file, params, title)
%INIT_FIG   Initialize a struct to hold metadata about figures.
%   FIG = INIT_FIG() initializes a fig with default values.
%
%   FIG = INIT_FIG(NAME,FIGTYPE,FILE,PARAMS,TITLE) initializes a fig
%   object with fields NAME, FIGTYPE, FILE, PARAMS, and TITLE.
%
%   Fields:
%     'name'    string identifier used to reference the fig object
%     'title'   string used for display to describe the figures
%     'figtype' type of figures held in this object
%     'file'    string or cell array of strings holding filenames
%               of figures
%     'params'  struct containing the options used to create the
%               figures
%

if ~exist('name','var')
  name = '';
end
if ~exist('type','var')
  type = '';
end
if ~exist('file','var')
  file = '';
end
if ~exist('params','var')
  params = struct();
end
if ~exist('title','var')
  title = '';
end

if iscell(file) & isempty(file)
  file = {''};
end

fig = struct('name',name, 'title',title, 'type',figtype, 'file',file, 'params',params);
