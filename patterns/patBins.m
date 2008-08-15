function [pat2,bins,events,evmod] = patBins(pat1,params,events)
%PATBINS   Apply bins to dimensions of a pat object.
%   [PAT2,BINS,EVENTS,EVMOD] = PATBINS(PAT1,PARAMS,EVENTS) alters the 
%   dimensions information contained in PAT1, in preparation for binning 
%   a pattern.  Options for what dimensions to bin and how are contained 
%   in the PARAMS struct.  EVENTS can optionally be input to avoid having
%   to reload it.
%
%   PAT2 is the altered pat object. BINS contains information
%   that can be passed into PATMEANS to carry out binning of a pattern.
%   EVENTS, an altered events struct, will also be output if the events
%   dimension has been altered or it was part of the input.  EVMOD
%   is true if the events dimension was altered, otherwise false.
%
%   Params:
%     'field'           Specifies event bins. Each cell is input to
%                       binEventsField
%     'eventbinlabels'  Cell array of labels corresponding to each event bin
%     'chanbins'        Specifies channel bins. Each cell can be a vector
%                       of channel numbers, a cell array of regions, or a
%                       string to be passed into filterStruct
%     'chanbinlabels'   Cell array of labels corresponding to each channel
%                       group
%     'MSbins'          Specifies time bins. Should be a nbinsX2 matrix,
%                       with MSbins(i,:) giving the range of MS values for 
%                       bin i
%     'MSbinlabels'     Cell array of labels corresponding to each time bin
%     'freqbins'        Specifies frequency bins. Should be a nbinsX2 matrix,
%                       with freqbins(i,:) giving the range of frequencies
%                       for bin i
%     'freqbinlabels'   Cell array of labels corresponding to each frequency
%                       bin
%
%   See also patMeans, modify_pats, patFilt.
%

params = structDefaults(params,  'field', '',  'eventbinlabels', '',  'chanbins', [],  'chanbinlabels', {},  'MSbins', [],  'MSbinlabels', {},  'freqbins', [],  'freqbinlabels', {});

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


function [ev2, events2, bine] = eventBins(ev1, params, events1)
%EVENTBINS   Apply bins to an events dimension.
%   [EV2,EVENTS2] = EVENTBINS(EV1,PARAMS) bins the events
%   dimension whose information is stored in EV1 using options in
%   PARAMS, and outputs EV2, a new dimension struct, and EVENTS2,
%   a struct with one field, "type."
%
%   [EV2,EVENTS2,BINE] = EVENTBINS(EV1,PARAMS) also outputs BINE,
%   a cell array of indices of the original events struct for
%   each unique value of EVENTS2.
%

if ~exist('params', 'var')
	params = struct();
end

params = structDefaults(params, 'field', '',  'eventbinlabels', '');

if ~exist('events1', 'var')
	load(ev1.file);
	events1 = events;
end

ev2 = ev1;

% generate a new events field, one value per bin
vec = binEventsField(events1, params.field);

% find the events corresponding to each condition
vals = unique(vec);
ev2.len = length(vals);
for j=1:length(vals)

	if iscell(vals)
		% assume all values are strings
		if ~isempty(params.eventbinlabels)
			events2(j).type = params.eventbinlabels{j};
			else
			events2(j).type = vals{j};
		end
		bine{j} = find(strcmp(vec, vals{j}));

		else
		% values are numeric
		if ~isempty(params.eventbinlabels)
			events2(j).type = params.eventbinlabels{j};
			else
			events2(j).type = vals(j);
		end
		bine{j} = find(vec==vals(j));
	end

end % unique event types


function [chan2, binc] = chanBins(chan1, params)
%CHANBINS   Apply binning to a channel dimension.
%   [CHAN2] = CHANBINS(CHAN1,PARAMS) bins the channels dimension
%   whose information is stored in CHAN1 using options in PARAMS,
%   and outputs a new chan struct CHAN2.
%
%   [CHAN2,BINC] = CHANBINS(CHAN1,PARAMS) also outputs BINC,
%   a cell array of indices of the original chan struct for
%   each channel group in CHAN2.
%
%   OPTIONAL PARAMS:
%      CHANBINS - a cell array indicating how to make each
%                 channel group; each cell can be a vector
%                 of channel numbers, a cell array of regions,
%                 or a string to be passed into FILTERSTRUCT.
%      CHANBINLABELS - a cell array containing names for each
%                      channel group
%      

if ~exist('params', 'var')
	params = struct();
end

params = structDefaults(params, 'chanbins', {},  'chanbinlabels', {});

if isempty(params.chanbins)
	% no binning will occur
	for c=1:length(chan1)
		binc{c} = c;
	end
	chan2 = chan1;
	return
end

% define the new channel bins
for c=1:length(params.chanbins)

	if ~iscell(params.chanbins)
		% each bin contains just one channel
		binc{c} = params.chanbins(c);

		elseif isnumeric(params.chanbins{c})
		% this bin contains multiple channel numbers
		binc{c} = find(inStruct(chan1, 'ismember(number, varargin{1})', params.chanbins{c}));

		elseif iscell(params.chanbins{c})
		% this bin contains multiple regions
		regions = getStructField(chan1, 'region');
		binc{c} = find(inStruct(chan1, 'ismember(region, varargin{1})', params.chanbins{c}));

		elseif isstr(params.chanbins{c})
		% create the bin using a chanfilter string
		binc{c} = find(inStruct(chan1, 'strcmp(region, varargin{1})', params.chanbins{c}));
	end

	% make the new chan struct
	theseChans = chan1(binc{c});
	chan2(c).number = getStructField(theseChans, 'number');
	chan2(c).region = getStructField(theseChans, 'region');
end

% update the channel labels
for c=1:length(chan2)
	if ~isempty(params.chanbinlabels)
		% use user-specified labels
		chan2(c).label = params.chanbinlabels{c};

		elseif length(unique({chan2.region}))==length(chan2)
		% if each bin has a unique region, we can use that
		chan2(c).label = chan2(c).region;

		else
		% just use the channel number(s)
		chan2(c).label = num2str(chan2(c).number);
	end
end


function [time2, bint] = timeBins(time1, params)
%[time, bint] = function(timeBins, params)

if ~exist('time1', 'var')
  time1 = [];
end
if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'MSbins', {},  'MSbinlabels', {});

% make the new time bins
if ~isempty(params.MSbins)

  % get the current list of times
  avgtime = [time1.avg];
  
  if length(params.MSbins)==1
		stepSize = params.MSbins;
    params.MSbins = makeBins(stepSize,avgtime(1),avgtime(end));
  end
  
  for t=1:size(params.MSbins, 1)
    % define this bin
    bint{t} = find(avgtime>=params.MSbins(t,1) & avgtime<params.MSbins(t,2));

    % get ms value for each sample in the new time bin
    time2(t).MSvals = avgtime(bint{t});
    time2(t).avg = mean(params.MSbins(t,:));
    
    % update the time bin label
    if ~isempty(params.MSbinlabels)
      time2(t).label = params.MSbinlabels{t};
    else
      time2(t).label = sprintf('%d to %d ms', time2(t).MSvals(1), time2(t).MSvals(end));
    end
  end
	
elseif ~isempty(time1) % just copy info from time1

  % copy the existing struct
  time2 = time1;
  
  % define the bins
  for t=1:length(time2)
    bint{t} = t;
  end
  
else % no time info; can't create the struct or bin it
  time2 = init_time();
  bint = {};
end


function [freq2, binf] = freqBins(freq1, params)
%[freq2, binf] = freqBins(freq1, params)

if ~exist('freq1', 'var')
  freq1 = [];
end
if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'freqbins', {},  'freqbinlabels', {});

% make the new freq bins
if ~isempty(params.freqbins)
  
  % get the current list of frequencies
  avgfreq = [freq1.avg];
  
  for f=1:length(params.freqbins)
    % define this bin
    binf{f} = find(avgfreq>=params.freqbins(f,1) & avgfreq<params.freqbins(f,2));
    
    freq2(f).vals = avgfreq(binf{f});
    freq2(f).avg = mean(freq2(f).vals);
    
    % update the labels
    if ~isempty(params.freqbinlabels)
      freq2(f).label = params.freqbinlabels{f};
    else
      freq2(f).label = sprintf('%d to %d Hz', freq2(f).vals(1), freq2(f).vals(end));
    end
  end
  
elseif ~isempty(freq1)
  
  % copy the existing struct
  freq2 = freq1;
  
  % define the bins
  for f=1:length(freq2)
    binf{f} = f;
  end
  
else
  freq2 = init_freq();
  binf = {};
end
