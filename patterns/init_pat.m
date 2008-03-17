function pat = init_pat(patname, file, params, ev, chan, time, freq)
%pat = init_pat(patname, file, params, ev, chan, time, freq)

if ~exist('patname', 'var')
  patname = '';
end
if ~exist('file', 'var')
  file = '';
end
if ~exist('params', 'var')
  params = struct();
end
if ~exist('ev', 'var')
  ev = struct();
end
if ~exist('chan', 'var')
  chan = struct();
end
if ~exist('time', 'var')
  time = struct();
end
if ~exist('freq', 'var')
  freq = struct();
end

dim = struct('ev', ev,  'chan', chan,  'time', time,  'freq', freq);

pat = struct('name', patname,  'file', file,  'params', params,  'dim', dim);