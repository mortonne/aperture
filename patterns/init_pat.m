function pat = init_pat(patname, file, source, params, ev, chan, time, freq)
%pat = init_pat(patname, file, params, ev, chan, time, freq)

if ~exist('patname', 'var')
  patname = '';
end
if ~exist('file', 'var')
  file = '';
end
if ~exist('source','var')
  source = '';
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

if isfield(ev, 'ev')
	% assume a dim struct was passed in
	dim = ev;
	else
	% create one from the standard dimensions
	dim = struct('ev', ev,  'chan', chan,  'time', time,  'freq', freq);
end

pat = struct('name',patname, 'file',file, 'source',source, 'params',params, 'dim',dim);
