function pat = init_pat(name, file, source, params, ev, chan, time, freq)
%INIT_PAT   Initialize a structure to hold metadata about a pattern.
%
%  pat = init_pat(name, file, source, params, ev, chan, time, freq)
%
%  Initializes a "pat" object, which holds metadata about a pattern.
%
%  INPUTS:
%     name:  string identifier.
%
%     file:  file where the pattern matrix is stored.
%
%   source:  name of the object from which this pattern is derived (usually 
%            a subj structure).
%
%   params:  structure containing the options used to create this pattern.
%
%       ev:  structure with information about the events dimension.
%
%     chan:  channels dimension.
%
%     time:  time dimension.
%
%     freq:  frequency dimension.
%
%  OUTPUTS:
%      pat:  a standard "pat" object.

% defaults
if ~exist('name', 'var')
  name = '';
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
  chan = struct('number', [],  'region', '',  'label', '');
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

% make the pat structure
pat = struct('name',name, 'file','', 'source',source, 'params',params, 'dim',dim);

% if we assign this in call to struct, pat will be made a vector structure
pat.file = file;
