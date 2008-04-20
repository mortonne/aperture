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
if ~exist('ev', 'var')
  ev = struct('name', '',  'file', '',  'len', []);
end
if ~exist('chan', 'var')
  chan = struct('number', [],  'region', {},  'label', {});
end
if ~exist('time', 'var')
  time = init_time();
end
if ~exist('freq', 'var')
  freq = init_freq();
end

dim = struct('ev', ev,  'chan', chan,  'time', time,  'freq', freq);

fig = struct('name', name,  'type', type, 'file', file,  'params', params,  'dim', dim);