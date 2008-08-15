function [pattern, events] = loadPat(pat, params)
%LOADPAT   Load a pattern from a pat object.
%   PATTERN = LOADPAT(PAT,PARAMS) loads PAT.file using options
%   specified in the PARAMS struct.
%
%   [PATTERN,EVENTS] = LOADPAT(PAT,PARAMS) also returns the
%   corresponding EVENTS.
%
%   Params:
%     'loadSingles' If true (default is false), the pattern will
%                   be loaded as an array of singles
%     'whichPat'    If pat.file is a cell array, specifies which
%                   file to load
%     'catDim'      If the pattern is saved in multiple files,
%                   this specifies which dimension to concatenate
%                   over when reconstituting the pattern
%

if isstr(pat)
	% just the pat file has been input
	newpat.file = pat;
	pat = newpat;
end
if ~exist('params', 'var')
  params = [];
end

params = structDefaults(params, 'loadSingles', 0,  'whichPat', [],  'catDim', []);

% if there are multiple patterns for this pat object, choose one
if iscell(pat.file) & ~isempty(params.whichPat)
  pat.file = pat.file{params.whichPat};
end

% reconstitute pattern if necessary
if iscell(pat.file) & ~isempty(params.catDim)
  pattern = NaN(pat.dim.ev.len, length(pat.dim.chan), length(pat.dim.time), length(pat.dim.freq));
  allDim = {':',':',':',':'};
  for i=1:length(pat.file)
    s = load(pat.file{i});
    ind = allDim;
    ind{params.catDim} = i;
    
    pattern(ind{:}) = s.pattern;
  end
else
  load(pat.file);
end

% change to lower precision if desired
if params.loadSingles
	pattern = single(pattern);
end

% load events
if nargout==2
  events = loadEvents(pat.dim.ev.file);
else
  events = struct;
end
