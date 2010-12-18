function [pat, bins] = patBins(pat, varargin)
%PATBINS   Apply bins to dimensions of a pat object.
%
%  Bin dimensions of a pattern. Determines the indices of the pattern
%  for each bin, and updates the dimension information in the pat
%  object. The pattern matrix is not modified.
%
%  [pat, bins] = patBins(pat, ...)
%
%  INPUTS:
%      pat:  a pattern object.
%
%  OUTPUTS:
%      pat:  the modified pattern object.
%
%     bins:  a cell array with one cell for each dimension of the
%            pattern. Each cell contains a cell array with one cell for
%            each bin, which contains the indices in the pattern that
%            correspond to the bin. If a dimension is not being binned,
%            the cell for that dimension will be empty.
%
%  PARAMS:
%  Options may be specified using parameter, value pairs or a structure.
%  Default values are shown in parentheses.
%   eventbins      - cell array specifying event bins. Each cell is
%                    input to make_event_bins to create indices. ([])
%   eventbinlabels - cell array of strings giving a label for each event
%                    bin. ({})
%   eventbinlevels - used only if specifying bins by a conjunction of
%                    multiple factors. This includes if eventbins is a
%                    cell array of strings with events fields, or a cell
%                    array of cell arrays containing "expr" inputs for
%                    inStruct. This is used to specify labels for the
%                    different levels of the factors. The label for
%                    factor i, level j goes in eventbinlevels{i}{j}.
%                    ({})
%   chanbins       - cell array specifying channel bins. Each cell can
%                    be a vector of channel numbers, a cell array of
%                    channel labels, or a string to be passed into
%                    filterStruct. ([])
%   chanbinlabels  - cell array of string labels for each channel bin.
%                    ({})
%   timebins       - [nbins X 2] array specifying time bins.
%                    timebins(i,:) gives the range of millisecond values
%                    to include in bin i. Use make_bins to generate
%                    evenly spaced bins. ([])
%   timebinlabels  - cell array of string labels for each time bin. ({})
%   freqbins       - [nbins X 2] array specifying frequency bins.
%                    freqbins(i,:) gives the range of frequencies to
%                    include in bin i. ([])
%   freqbinlabels  - cell array of string labels for each frequency bin.
%                    ({})
%
%  All *bins fields may also be set to:
%   ':'    - place all indices of the dimension in one bin
%   'iter' - place each index in its own bin
%
%  EXAMPLE:
%   sample pattern with three sessions; want to get average for each
%   session and average over 0-1000 ms
%   >> patsize(pat.dim)
%      253   129    90    18
%   >> [pat, bins] = patBins(pat, 'eventbins', 'session', ...
%                                 'timebins', [0 1000]);
%   >> patsize(pat.dim)
%      3     129    1     18
%   >> bins
%      {1x3 cell}     []    {1x1 cell}     []
%
%  See also make_bins, patMeans, modify_pattern, patFilt.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass a pattern object.')
end
if ~isfield(pat.dim.ev, 'modified')
  pat.dim.ev.modified = false;
end

% default parameters
defaults.eventbins = [];
defaults.eventbinlabels = {};
defaults.eventbinlevels = {};
defaults.chanbins = [];
defaults.chanbinlabels = {};
defaults.timebins = [];
defaults.timebinlabels = {};
defaults.freqbins = [];
defaults.freqbinlabels = {};
defaults.MSbins = [];
defaults.MSbinlabels = {};
params = propval(varargin, defaults);

% backwards compatibility
if ~isempty(params.MSbins)
  warning('MSbins is deprecated. use timebins instead.')
  params.timebins = params.MSbins;
end
if ~isempty(params.MSbinlabels)
  warning('MSbinlabels is deprecated. use timebinlabels instead.')
  params.timebinlabels = params.MSbinlabels;
end

% initialize
bins = cell(1, 4);

% events
if ~isempty(params.eventbins)
  % load events
  events = get_dim(pat.dim, 'ev');
  [events, bins{1}] = event_bins(events, params.eventbins, ...
                                 params.eventbinlabels, ...
                                 params.eventbinlevels);
  
  % save the events to the new ev object
  pat.dim = set_dim(pat.dim, 'ev', events, 'ws');
end

% channels
if ~isempty(params.chanbins)
  [chan, bins{2}] = chan_bins(get_dim(pat.dim, 'chan'), params.chanbins, ...
                              params.chanbinlabels);
  pat.dim = set_dim(pat.dim, 'chan', chan, 'ws');
end

% time
if ~isempty(params.timebins)
  [time, bins{3}] = time_bins(get_dim(pat.dim, 'time'), params.timebins, ...
                              params.timebinlabels);
  pat.dim = set_dim(pat.dim, 'time', time, 'ws');
end

% frequency
if ~isempty(params.freqbins)
  [freq, bins{4}] = freq_bins(get_dim(pat.dim, 'freq'), params.freqbins, ...
                              params.freqbinlabels);
  pat.dim = set_dim(pat.dim, 'freq', freq, 'ws');
end

% check the dimensions
psize = patsize(pat.dim);
if any(~psize)
  error('A dimension of pattern %s was binned into oblivion.', pat.name);
end


function [events2, bins] = event_bins(events1, bin_defs, labels, levels)
  %EVENT_BINS   Apply bins to an events dimension.
  %
  %  [ev, bins] = event_bins(ev, bin_defs, labels, levels)

  % translate universal bin codes
  if ischar(bin_defs)
    if strcmp(bin_defs, ':')
      bin_defs = 'overall';
    elseif strcmp(bin_defs, 'iter')
      bin_defs = 'none';
    end
  end
  
  % load the events
  fnames = fieldnames(events1);
  
  % create new event fields if necessary
  if (iscell(bin_defs) && ~iscellstr(bin_defs)) || ...
     (iscellstr(bin_defs) && all(ismember(bin_defs, fieldnames(events1))))
    for i = 1:length(bin_defs)
      % create a new field with one value for each filter/field value
      [vec, bin_levels{i}] = make_event_index(events1, bin_defs{i});
      f{i} = sprintf('factor%i', i);
      c = num2cell(vec);
      [events1.(f{i})] = c{:};
      
      % will now use this field for binning
      bin_defs{i} = f{i};
    end
    conj = true;
  else
    conj = false;
  end
  
  % get a vector with one value for each bin
  [vec, bin_levels] = make_event_index(events1, bin_defs);
  [n_bins, n_factors] = size(bin_levels);
  
  % create a new collapsed events struct
  events2 = [];
  bins = cell(1, n_bins);
  n = NaN(1, n_bins);
  for i = 1:n_bins
    bins{i} = find(vec == i);
    
    % salvage fields that have the same value for this whole bin
    bin_event = collapse_struct(events1(bins{i}));
    events2 = cat_structs(events2, bin_event);
    n(i) = length(bins{i});
  end
  
  % add a field with the number of events going into each bin
  c = num2cell(n);
  [events2.n] = c{:};

  % set the label field
  if isempty(labels)
    if conj
      % define labels based on the levels of each factor
      labels = cell(1, n_bins);
      for i = 1:n_bins
        labels{i} = '';
        for j = 1:n_factors
          % number of the level within this factor
          this_label = bin_levels{i,j};
          if ~isempty(levels)
            % if specified, use a custom label
            events2(i).(f{j}) = levels{j}{this_label};
            labels{i} = [labels{i} ' ' levels{j}{this_label}];
          else
            % just print the level number
            labels{i} = [labels{i} num2str(this_label)];
          end
        end
        labels{i} = strtrim(labels{i});
      end
      
    elseif iscellstr(bin_levels)
      labels = bin_levels;
      
    elseif isnumeric(bin_levels{1})
      % assuming that the field this is derived from had uniform type;
      % if not, this may throw an error
      labels = cellfun(@num2str, bin_levels, 'UniformOutput', false);
      
    else
      % can't make labels from the events field values
      % try generating labels from the standard fields
      dim.mat = events2;
      dim.len = length(events2);
      labels = get_dim_labels(struct('ev', dim), 'ev');
    end
  end
  [events2.label] = labels{:};


function [chan2, bins] = chan_bins(chan1, bin_defs, labels)
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
  %              {'r1' 'r2' 'r3' ...} - a cell array of labels
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
  %
  %  NOTES:
  %   To assume and maintain in the output chan structure:
  %   number is defined and unique. It contains a numeric scalar.
  %   label is defined and unique. It contains a string.
  %   there may be other fields, which will be kept if possible.

  % get numbers and regions from the old channels struct
  dim.chan = chan1;
  chan_numbers = get_dim_vals(dim, 'chan');
  chan_labels = get_dim_labels(dim, 'chan');
  
  % translate universal bin defs
  if ischar(bin_defs)
    if strcmp(bin_defs, ':')
      bin_defs = {chan_numbers};
    elseif strcmp(bin_defs, 'iter')
      bin_defs = num2cell(chan_numbers);
    end
  end
  
  % input checks
  if isnumeric(bin_defs)
    bin_defs = num2cell(bin_defs);
  end
  if ~iscell(bin_defs)
    bin_defs = {bin_defs};
  end
  if ~iscellstr(labels)
    error('labels must be a cell array of strings.')
  elseif ~isempty(labels) && length(labels) ~= length(bin_defs)
    error('labels must be the same length as bin_defs.')
  end
  
  % define each channel bin
  c = bin_defs;
  n_bins = length(c);
  bins = cell(1, n_bins);
  chan2 = [];
  for i = 1:n_bins
    if isnumeric(c{i})
      % channel numbers
      bins{i} = find(ismember(chan_numbers, c{i}));
    elseif iscellstr(c{i})
      % channel labels
      bins{i} = find(ismember(chan_labels, c{i}));
    elseif ischar(c{i})
      % filter string
      bins{i} = find(inStruct(chan1, c{i}));
    else
      error('Channel bin %d definition is invalid', i)
    end
    
    % remove fields that vary between elements
    bin_chan = collapse_struct(chan1(bins{i}));
    
    % if multiple channels in bin, mark for assignment
    % of a new number (will be unique)
    if ~isfield(bin_chan, 'number')
      bin_chan.number = NaN;
    end
    
    if ~isempty(labels)
      % user-defined label
      bin_chan.label = labels{i};
    elseif ~isfield(bin_chan, 'label')
      % combine the labels of included channels
      bin_chan.label = strtrim(sprintf('%s ', chan1(bins{i}).label));
    end
    
    % add this bin
    chan2 = cat_structs(chan2, bin_chan);
  end
  
  % assign new channel numbers where needed
  bad = isnan([chan2.number]);
  if any(bad)
    % use only unused numbers
    new = num2cell(setdiff(1:n_bins, [chan2(~bad).number]));
    [chan2(bad).number] = new{:};
  end

  
function [time2, bins] = time_bins(time1, bin_defs, labels)
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
  if ~iscellstr(labels)
    error('labels must be a cell array of strings.')
  elseif ~isempty(labels) && length(labels) ~= size(bin_defs, 1)
    error('labels must be the same length as bin_defs.')
  end

  if ischar(bin_defs)
    % universal bin defs
    if strcmp(bin_defs, ':')
      bins = {1:length(time1)};
      bin_defs = [time1(1).range(1) time1(end).range(end)];
    elseif strcmp(bin_defs, 'iter')
      bins = num2cell(1:length(time1));
      bin_defs = cat(1, time1.range);
    end
  elseif size(bin_defs, 2) > 1 && isunique(diff(bin_defs, [], 2))
    % if multiple bins of the same size, make the last bin non-inclusive
    bins = apply_bins([time1.avg], bin_defs, false);
  else
    % the last bin will be inclusive
    bins = apply_bins([time1.avg], bin_defs);
  end
  
  % create the new time structure
  time2 = struct('range', cell(size(bins)), 'avg', [], 'label', '');
  for i = 1:length(bins)
    time2(i).range = bin_defs(i,:);
    time2(i).avg = nanmean(time2(i).range);
  end

  % update the labels
  if isempty(labels)
    f = @(x)sprintf('%d to %d ms', x(1), x(end));
    labels = cellfun(f, {time2.range}, 'UniformOutput', false);
  end
  [time2.label] = labels{:};


function [freq2, bins] = freq_bins(freq1, bin_defs, labels)
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
  if ~iscellstr(labels)
    error('labels must be a cell array of strings.')
  elseif ~isempty(labels) && length(labels) ~= size(bin_defs, 1)
    error('labels must be the same length as bin_defs.')
  end

  if ~isfield(freq1, 'range')
    [freq1.range] = freq1.vals;
  end
  
  if ischar(bin_defs)
    % universal bin defs
    if strcmp(bin_defs, ':')
      bins = {1:length(freq1)};
      bin_defs = [freq1(1).range(1) freq1(end).range(end)];
    elseif strcmp(bin_defs, 'iter')
      bins = num2cell(1:length(freq1));
      bin_defs = cat(1, freq1.range);
    end
  else
    % get the indices corresponding to each bin
    bins = apply_bins([freq1.avg], bin_defs);
  end

  % create the new time structure
  freq2 = struct('range', cell(size(bins)), 'avg', [], 'label', '');
  for i = 1:length(bins)
    freq2(i).range = bin_defs(i,:);
    freq2(i).avg = 2 ^ mean(log2(freq2(i).range));
  end
  
  % update the labels
  if isempty(labels)
    f = @(x)sprintf('%d to %d Hz', round(x(1)), round(x(end)));
    labels = cellfun(f, {freq2.range}, 'UniformOutput', false);
  end
  [freq2.label] = labels{:};

