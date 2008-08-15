function [pat,inds,events,evmod] = patFilt(pat,params,events)
%PATFILT   Filter the dimensions of a pat object.
%   [PAT,INDS,EVENTS,EVMOD] = PATFILT(PAT,PARAMS,EVENTS) alters the
%   the dimensions information contained in PAT, in preparation for
%   filtering a pattern.  Options for what dimensions to filter and
%   how are contained in the PARAMS struct.  EVENTS can optionally 
%   be input to avoid having to reload it.
%
%   INDS gives a cell array of the indices required to reference 
%   the pattern and carry out the filtering.
%   
%   EVENTS, an altered events struct, will also be output if the events
%   dimension has been altered or it was part of the input.  EVMOD
%   is true if the events dimension was altered, otherwise false.
%
%   Example:
%    params = struct('eventFilter','strcmp(type,''WORD'')');
%    [pat,inds] = patFilt(pat,params);
%    pattern = loadPat(pat);
%    pattern = pattern(inds{:});
%
%   See also modify_pats, patBins, patMeans.
%

params = structDefaults(params,  'eventFilter', '',  'chanFilter', '',  'timeFilter', '',  'freqFilter', '');

% initialize
for i=1:4
  inds{i} = ':';
end
evmod = 0;

% start the averaging
%fprintf('Binning pattern "%s"...', pat.name)

% EVENTS
if ~isempty(params.eventFilter)
	if ~exist('events','var') || isempty(events)
		load(pat.dim.ev.file);
	end
	
	inds{1} = inStruct(events, params.eventFilter);
	events = events(inds{1});
	pat.dim.ev.len = length(events);
	
	evmod = 1;
end

% CHANNELS
if ~isempty(params.chanFilter)
	inds{2} = inStruct(pat.dim.chan, params.chanFilter);
	pat.dim.chan = pat.dim.chan(inds{2});
end

% TIME
if ~isempty(params.timeFilter)
	inds{3} = inStruct(pat.dim.time, params.timeFilter);
	pat.dim.time = pat.dim.time(inds{3});
end

% FREQUENCY
if ~isempty(params.freqFilter)
  inds{4} = inStruct(pat.dim.freq, params.freqFilter);
	pat.dim.freq = pat.dim.freq(inds{4});
end
%fprintf('\n')

% check the dimensions
psize = patsize(pat.dim);
if any(~psize)
	error('A dimension of pattern %s was filtered into oblivion.', pat.name);
end

if ~exist('events','var')
	events = struct;
end
