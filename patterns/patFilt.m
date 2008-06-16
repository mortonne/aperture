function [pat,inds,events,evmod] = patFilt(pat,params,events)
%
%PATBINS   Filter the dimensions of a pat object.
%   [PAT2,INDS] = PATBINS(PAT,PARAMS) alters the dimensions information
%   contained in PAT1, in preparation for binning a pattern.  Options for
%   what dimensions to bin and how are contained in the PARAMS struct.
%
%   PAT2 is the altered pat object. inds contains information
%   that can be passed into PATMEANS to carry out binning of a pattern.
%   EVENTS, an altered events struct, will also be output if the events
%   dimension has been changed.
%
%   See EVENTBINS, CHANBINS, TIMEBINS, and FREQBINS for options for each
%   dimension.
%

params = structDefaults(params,  'eventFilter', '',  'chanFilter', '',  'timeFilter', '',  'freqFilter', '');

% initialize
inds = cell(1,4);
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
fprintf('\n')

% check the dimensions
psize = patsize(pat.dim);
if any(~psize)
	error('A dimension of pattern %s was filtered into oblivion.', pat.name);
end

if ~exist('events','var')
	events = struct;
end
