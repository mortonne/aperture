function fig = init_fig(name, file, source)
%INIT_FIG   Initialize a struct to hold metadata about figures.
%
%  fig = init_fig(name, file, source)
%
%  INPUTS:
%     name:  string identifier for this fig object.
%
%     file:  string or cell array of strings giving paths to
%            saved figures.
%
%   source:  name of the parent object.
%
%  OUTPUTS:
%      fig:  a standard figure object.
%
%  See also create_fig.

% input checks
if ~exist('name','var')
  name = '';
elseif ~ischar(name)
  error('name must be a string.')
end
if ~exist('file','var')
  file = '';
elseif (~ischar(file) && ~iscell(file))
  error('file must be a string or a cell array of strings.')
elseif ischar(file)
  if ~exist(file,'file')
    error('File does not exist: %s', file)
  end
elseif iscell(file)
  if ~all(cellfun(@ischar, file))
    error('file must be a string or a cell array of strings.')
  end
end
if ~exist('source','var')
  source = '';
elseif ~ischar(source)
  error('source must be a string.')
end

if iscell(file) & isempty(file)
  file = {''};
end

% create the fig structure
fig = struct('name',name, 'file','', 'source',source);

% now add the file cell array
fig.file = file;
