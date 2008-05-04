function fig = init_fig(name, figtype, file, params)
%fig = init_fig(name, figtype, file, params)

if ~exist('name', 'var')
  name = '';
end
if ~exist('type', 'var')
  type = '';
end
if ~exist('file', 'var')
  file = '';
end
if ~exist('params', 'var')
  params = struct();
end

if iscell(file) & isempty(file)
  file = {''};
end

fig = struct('name', name,  'type', figtype, 'file', file,  'params', params);
