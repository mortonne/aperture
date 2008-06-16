function [pat2,bins,events,evmod] = patBins(pat1,params,events)
%
%PATBINS   Apply bins to dimensions of a pat object.
%   [PAT2,BINS] = PATBINS(PAT1,PARAMS) alters the dimensions information
%   contained in PAT1, in preparation for binning a pattern.  Options for
%   what dimensions to bin and how are contained in the PARAMS struct.
%
%   PAT2 is the altered pat object. BINS contains information
%   that can be passed into PATMEANS to carry out binning of a pattern.
%   EVENTS, an altered events struct, will also be output if the events
%   dimension has been changed.
%
%   See EVENTBINS, CHANBINS, TIMEBINS, and FREQBINS for options for each
%   dimension.
%

params = structDefaults(params,  'masks', {},  'field', '',  'eventBinLabels', '',  'chanbins', [],  'chanbinlabels', {},  'MSbins', [],  'MSbinlabels', {},  'freqbins', [],  'freqbinlabels', {});

% initialize
pat2 = pat1;
bins = cell(1,4);
evmod = 0;

% start the averaging
%fprintf('Binning pattern "%s"...', pat1.name)

% EVENTS
if ~isempty(params.field)
  %fprintf('events...');

	if ~exist('events','var') || isempty(events)
		load(pat1.dim.ev.file);
	end

  % bin events using a field from the events struct
  if exist('events', 'var')
    [pat2.dim.ev, events, bins{1}] = eventBins(pat1.dim.ev, params, events);
  else
    [pat2.dim.ev, events, bins{1}] = eventBins(pat1.dim.ev, params);
  end

	evmod = 1;
end

% CHANNELS
if ~isempty(params.chanbins)
  %fprintf('channels...');
  
  % bin channels by number or region
  [pat2.dim.chan, bins{2}] = chanBins(pat1.dim.chan, params);
end

% TIME
if ~isempty(params.MSbins)
  %fprintf('time...');
  
  % bin time using MS windows
  [pat2.dim.time, bins{3}] = timeBins(pat1.dim.time, params);
end

% FREQUENCY
if ~isempty(params.freqbins)
  %fprintf('frequency...');
  
  % bin frequency using freq windows
  [pat2.dim.freq, bins{4}] = freqBins(pat1.dim.freq, params);
end
%fprintf('\n')

% check the dimensions
psize = patsize(pat2.dim);
if any(~psize)
	error('A dimension of pattern %s was binned into oblivion.', pat.name);
end

if ~exist('events','var')
	events = struct;
end
