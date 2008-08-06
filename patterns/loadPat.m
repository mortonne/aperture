function [pattern, events] = loadPat(pat, params)
%
%LOADPAT - loads one subject's pattern, and applies any specified
%masks and event filters
%
% FUNCTION: [pattern, events] = loadPat(pat, params)
%
% INPUT: pat - struct holding information about a pattern
%        params - required fields: none
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), whichPat
%                 (necessary if pat.file is a cell array with
%                 filenames of multiple patterns), catDim
%                 (necessary if the pattern is split on one
%                 dimension into multiple files - specifies which
%                 dimension to concatenate on)
%
% OUTPUT: loaded pattern, plus the events associated with the
% pattern
%

if isstr(pat)
	% just the pat file has been input
	newpat.file = pat;
	pat = newpat;
end
if ~exist('params', 'var')
  params = [];
end

params = structDefaults(params, 'masks', {},  'nComp', [],  'loadSingles', 0,  'whichPat', [],  'catDim', []);

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
