function fig = init_fig(name, type, file, params, ev, chan, time, freq)
%fig = init_fig(figname, file, params, ev, chan, time, freq)

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

fig = struct('name', name,  'type', type, 'file', file,  'params', params);