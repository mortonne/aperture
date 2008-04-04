function [pattern, events] = loadPat(pat, params, loadEv)
%
%LOADPAT - loads one subject's pattern, and applies any specified
%masks and event filters
%
% FUNCTION: [pattern, events] = loadPat(pat, params, loadEv)
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
%        loadEv - set to 1 to load the events associated with
%                     the pattern (default: 0)
%
% OUTPUT: loaded pattern, plus the events associated with the
% pattern if loadEv=1
%

if ~exist('loadEv', 'var')
  loadEv = 0;
end
if ~exist('params', 'var')
  params = [];
end

params = structDefaults(params, 'masks', {},  'eventFilter', '',  'chanFilter', '',  'whichPat', [],  'catDim', []);

% if there are multiple patterns for this pat object, choose one
if iscell(pat.file) & ~isempty(params.whichPat)
  pat.file = pat.file{params.whichPat};
end

% reconstitute pattern if necessary
if iscell(pat.file) & ~isempty(params.catDim)
  
  pattern = NaN(pat.dim.ev.len, length(pat.dim.chan), length(pat.dim.time), length(pat.dim.freq));
  for i=1:length(pat.file)
    s = load(pat.file{i});
    if params.catDim==2
      pattern(:,i,:,:) = s.pattern;
    elseif params.catDim==3
      pattern(:,:,i,:) = s.pattern;
    elseif params.catDim==4
      pattern(:,:,:,i) = s.pattern;
    end
  end
  
else
  load(pat.file);
end

% apply masks
if ~isempty(params.masks)
  mask = filterStruct(mask, 'ismember(name, varargin{1})', params.masks);
  for m=1:length(mask)
    pattern(mask(m).mat) = NaN;
  end
end

% load events
if loadEv | ~isempty(params.eventFilter)
  events = loadEvents(pat.dim.ev.file);
else
  events = [];
end

% filter events and pattern
if ~isempty(params.eventFilter)
  inds = inStruct(events, params.eventFilter);  
  pattern = pattern(inds,:,:,:);
  events = events(inds);
end

% filter channels
if ~isempty(params.chanFilter)
  inds = inStruct(pat.dim.chan, params.chanFilter);
  pattern = pattern(:,inds,:,:);
end
