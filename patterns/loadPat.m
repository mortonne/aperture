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

params = structDefaults(params, 'loadSingles',0, 'patnum', []);

if ~isempty(params.patnum)
  pat.file = pat.file{params.patnum};
end

% reconstitute pattern if necessary
if iscell(pat.file)
  % pattern is split
  if isfield(pat.dim,'splitdim') && ~isempty(pat.dim.splitdim)
    % concatenate along the split dimension to reform the pattern
    pattern = NaN(patsize(pat.dim));
    allDim = {':',':',':',':'};
    for i=1:length(pat.file)
      s = load(pat.file{i});
      ind = allDim;
      ind{pat.dim.splitdim} = i;
      pattern(ind{:}) = s.pattern;
    end
    else
    error('pat.dim must have a ''splitdim'' field.')
  end
  
  else
  % one file; load it up
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
