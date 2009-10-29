function [pat, bins] = patBins(pat, params)
%PATBINS   Apply bins to dimensions of a pat object.
%
%  [pat, bins] = patBins(pat, params)
%
%  Prepares a pattern for binning along one or more dimensions. The dim
%  field is updated, but the pattern is not modified. Use patMeans to
%  carry out the averaging within each bin.
%
%  INPUTS:
%      pat:  a pattern object.
%
%   params:  structure specifying options for binning the pattern.
%            See below for options.
%
%  OUTPUTS:
%      pat:  the modified pattern object.
%
%     bins:  a cell array with one cell for each dimension of the pattern.
%            Each cell contains a cell array with one cell for each bin,
%            which contains the indices in the pattern that correspond to
%            the bin.
%
%  PARAMS:
%   eventbins      - cell array specifying event bins. Each cell is input
%                    to make_event_bins. For backwards compatibility, this
%                    parameter can also be called 'field'
%   eventbinlabels - cell array of strings giving a label for each event
%                    bin
%   chanbins       - cell array specifying channel bins. Each cell can be
%                    a vector of channel numbers, a cell array of regions,
%                    or a string to be passed into filterStruct
%   chanbinlabels  - cell array of string labels for each channel bin
%   MSbins         - [nbins X 2] array specifying time bins. MSbins(i,:)
%                    gives the range of millisecond values for bin i
%   MSbinlabels    - cell array of string labels for each time bin
%   freqbins       - [nbins X 2] array specifying frequency bins. 
%                    freqbins(i,:) gives the range of frequencies for bin i
%   freqbinlabels  - cell array of string labels for each frequency bin
%
%  See also make_bins, patMeans, modify_pattern, patFilt.

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass a pattern object.')
end
if ~exist('params','var')
  params = struct;
elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~isfield(pat.dim.ev, 'modified')
  pat.dim.ev.modified = false;
end

% backwards compatibility
if isfield(params, 'field')
  params.eventbins = params.field;
  params = rmfield(params, 'field');
end

% default parameters
params = structDefaults(params, ...
                        'eventbins',      [],  ...
                        'eventbinlabels', {},  ...
                        'chanbins',       [],  ...
                        'chanbinlabels',  {},  ...
                        'MSbins',         [],  ...
                        'MSbinlabels',    {},  ...
                        'freqbins',       [],  ...
                        'freqbinlabels',  {});

% initialize
bins = cell(1,4);

% events
if ~isempty(params.eventbins)
  % load events
  ev = move_obj_to_workspace(pat.dim.ev);
  [pat.dim.ev, bins{1}] = event_bins(ev, params.eventbins, ...
                                     params.eventbinlabels);
end

% channels
if ~isempty(params.chanbins)
  [pat.dim.chan, bins{2}] = chan_bins(pat.dim.chan, ...
                                      params.chanbins, ...
                                      params.chanbinlabels);
end

% time
if ~isempty(params.MSbins)
  [pat.dim.time, bins{3}] = time_bins(pat.dim.time, ...
                                      params.MSbins, ...
                                      params.MSbinlabels);
end

% frequency
if ~isempty(params.freqbins)
  [pat.dim.freq, bins{4}] = freq_bins(pat.dim.freq, ...
                                      params.freqbins, ...
                                      params.freqbinlabels);
end

% check the dimensions
psize = patsize(pat.dim);
if any(~psize)
	error('A dimension of pattern %s was binned into oblivion.', pat.name);
end


function [ev, bins] = event_bins(ev, bin_defs, labels)
  %EVENT_BINS   Apply bins to an events dimension.
  %
  %  [ev, bins] = event_bins(ev, bin_defs, labels)
  %
  %  INPUTS:
  %        ev:  an ev object.
  %
  %  bin_defs:  a cell array with one cell per bin. See make_event_bins
  %             for possible values of each cell.
  %
  %    labels:  a cell array of strings indicating a label for each bin.
  %
  %  OUTPUTS:
  %        ev:  a modified ev object. The events structure is also
  %             modified and stored in ev.mat. There will be one event
  %             for each bin.
  %
  %      bins:  a cell array with one cell per bin, where each cell
  %             contains indices for the events in that bin.

  % input checks
  if ~exist('ev','var')
    error('You must pass an ev object.')
  elseif ~exist('bin_defs','var')
    error('You must define the bins.')
  end
  if ~exist('labels','var')
    labels = {};
  end

  % load the events
  events1 = get_mat(ev);
  fnames = fieldnames(events1);
  
  % generate a new events field, one value per bin
  vec = make_event_bins(events1, bin_defs);
  if ~(isnumeric(vec) || iscellstr(vec))
    error('The labels returned by make_event_bins have an invalid type.')
  end
  
  % get values that correspond to bins; NaNs are not included anywhere
  vals = unique(vec);
  if isnumeric(vals)
    vals = vals(~isnan(vals));
  end

  % set the labels field for the new events
  if isempty(labels)
    if iscellstr(vals)
      labels = vals;
    else
      labels = num2cell(vals);
    end
  end
  events2 = struct('label', labels);
  
  for i=1:length(vals)
    % get indices for this bin
    bins{i} = find(ismember(vec, vals(i)));
    
    % salvage fields that have the same value for this whole bin
    for j=1:length(fnames)
      u_field = unique(getStructField(events1, fnames{j}));
      if length(u_field)==1
        if iscell(u_field)
          events2(i).(fnames{j}) = u_field{1};
        else
          events2(i).(fnames{j}) = u_field;
        end
      end
    end  
  end

  % save the events to the new ev object
  ev = set_mat(ev, events2);
%endfunction

function [chan, bins] = chan_bins(chan, bin_defs, labels)
  %CHAN_BINS   Apply binning to a channel dimension.
  %
  %  [chan, bins] = chan_bins(chan, bin_defs, labels)
  %
  %  INPUTS:
  %      chan:  a channels structure.
  %
  %  bin_defs:  a cell array, where each cell defines one bin.
  %             Each cell may contain:
  %              [c1 c2 c2 ...] - an array of channel numbers
  %              {'r1' 'r2' 'r3' ...} - a cell array of region labels
  %              'filter'       - a string to be input to filterStruct
  %
  %    labels:  a cell array of strings giving a label for each
  %             bin.  If not specified, and each bin contains a unique
  %             region, region labels will be used as labels for each
  %             bin.  Otherwise, channel numbers will be used as labels.
  %
  %  OUTPUTS:
  %     chan:  the modified channels structure.
  %
  %     bins:  cell array where each cell contains the indices for
  %            the corresponding bin in the original channels dimension.

  % input checks
  if ~exist('chan','var') || ~isstruct(chan)
    error('You must pass a channels structure to bin.')
  elseif ~exist('bin_defs','var')
    error('You must pass bin definitions.')
  end
  if ~exist('labels','var')
    labels = {};
  elseif ~iscellstr(labels)
    error('labels must be a cell array of strings.')
  elseif ~isempty(labels) && length(labels)~=length(bin_defs)
    error('labels must be the same length as bin_defs.')
  end

  % get numbers and regions from the old channels struct
  c = bin_defs;
  numbers = [chan.number];
  regions = {chan.region};
  if length(numbers)>length(chan) || length(regions)>length(chan)
    error('Some channels have multiple channel numbers or regions associated with them. Perhaps you have already binned the channels dimension once.')
  end

  % backwards compatibility
  if isnumeric(c)
    c = num2cell(c);
  end
  
  % define the new channel bins
  for i=1:length(c)
    if isnumeric(c{i})
      % channel number(s)
      bins{i} = find(ismember(numbers, c{i}));
    elseif iscellstr(c{i})
      % region(s)
      bins{i} = find(ismember(regions, c{i}));
    elseif ischar(c{i})
      % filter string
      bins{i} = find(inStruct(chan, c{i}));
    end
    bin_numbers{i} = numbers(bins{i});
    uniq_regions = unique(regions(bins{i}));
    bin_regions{i} = [uniq_regions{:}];
  end

  % initialize the new channels structure
  chan = struct('number', bin_numbers, 'region', bin_regions);

  % update the channel labels
  if ~isempty(labels)
    [chan.label] = labels{:};
  elseif length(unique({chan.region}))==length(chan)
    % each bin has a unique region
    [chan.label] = chan.region;
  else
    % just use the channel numbers
    labels = cellfun(@num2str, {chan.number}, 'UniformOutput', false);
    [chan.label] = labels{:};
  end
%endfunction

function [time, bins] = time_bins(time, bin_defs, labels)
  %TIME_BINS   Apply binning to a time dimension.
  %
  %  [time, bins] = time_bins(time, bin_defs, labels)
  %
  %  INPUTS:
  %      time:  a time structure.
  %
  %  bin_defs:  
  %
  %    labels:  a cell array of strings for each bin.
  %
  %  OUTPUTS:
  %      time:  a modified time structure.
  %
  %      bins:  a cell array where each cell contains the indices for
  %             that bin.

  % input checks
  if ~exist('time','var') || ~isstruct(time)
    error('You must pass a time structure to bin.')
  elseif ~exist('bin_defs','var')
    error('You must pass bin definitions.')
  end
  if ~exist('labels','var')
    labels = {};
  elseif ~iscellstr(labels)
    error('labels must be a cell array of strings.')
  elseif ~isempty(labels) && length(labels)~=size(bin_defs, 1)
    error('labels must be the same length as bin_defs.')
  end

  avgs = [time.avg];
  for i=1:size(bin_defs,1)
    % find the time bins that fall in this range
    bin_range = bin_defs(i,:);
    bins{i} = find(avgs >= bin_range(1) & ...
                   avgs < bin_range(2));
    
    % save the original start and end samples from this bin
    if ~isempty(bins{i})
      start_val = time(bins{i}(1)).MSvals(1);
      end_val = time(bins{i}(end)).MSvals(end);
      bin_vals{i} = [start_val end_val];
    else
      bin_vals{i} = NaN(1,2);
    end
    bin_avgs{i} = mean(bin_vals{i});
  end

  % make the new structure
  time = struct('avg', bin_avgs, 'MSvals', bin_vals);

  % update the labels
  if isempty(labels)
    f = @(x)sprintf('%d to %d ms', x(1), x(end));
    labels = cellfun(f, {time.MSvals}, 'UniformOutput', false);
  end
  [time.label] = labels{:};
%endfunction

function [freq, bins] = freq_bins(freq, bin_defs, labels)
  %FREQ_BINS   Apply binning to a frequency dimension.
  %
  %  [freq, bins] = freq_bins(freq, bin_defs, labels)
  %
  %  INPUTS:
  %      freq:  a frequency structure.
  %
  %  bin_defs:  
  %
  %    labels:  a cell array of strings for each bin.
  %
  %  OUTPUTS:
  %      freq:  a modified frequency structure.
  %
  %      bins:  a cell array where each cell contains the indices for
  %             that bin.

  % input checks
  if ~exist('freq','var') || ~isstruct(freq)
    error('You must pass a freq structure to bin.')
  elseif ~exist('bin_defs','var')
    error('You must pass bin definitions.')
  end
  if ~exist('labels','var')
    labels = {};
  elseif ~iscellstr(labels)
    error('labels must be a cell array of strings.')
  elseif ~isempty(labels) && length(labels)~=size(bin_defs, 1)
    error('labels must be the same length as bin_defs.')
  end

  avgs = [freq.avg];
  for i=1:size(bin_defs,1)
    % find the freq bins that fall in this range
    bin_range = bin_defs(i,:);
    bins{i} = find(avgs >= bin_range(1) & ...
                   avgs < bin_range(2));
    
    % save the original start and end samples from this bin
    if ~isempty(bins{i})
      start_val = freq(bins{i}(1)).vals(1);
      end_val = freq(bins{i}(end)).vals(end);
      bin_vals{i} = [start_val end_val];
    else
      bin_vals{i} = NaN(1,2);
    end
    bin_avgs{i} = mean(bin_vals{i});
  end

  % make the new structure
  freq = struct('avg', bin_avgs, 'vals', bin_vals);

  % update the labels
  if isempty(labels)
    f = @(x)sprintf('%d to %d Hz', round(x(1)), round(x(end)));
    labels = cellfun(f, {freq.vals}, 'UniformOutput', false);
  end
  [freq.label] = labels{:};
%endfunction
