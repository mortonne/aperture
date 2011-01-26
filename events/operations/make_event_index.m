function [index, levels] = make_event_index(events, bins)
%MAKE_EVENT_INDEX   Divide an events structure into bins.
%
%  [index, levels] = make_event_index(events, bins)
%
%  INPUTS:
%   events:  an events structure.
%
%     bins:  input that specifies how to divide the events structure
%            into bins (see below).
%
%  OUTPUTS:
%    index:  a vector or cell array of strings the same length as
%            events, where each unique value indicates one bin. Events
%            that are not placed in any bin are marked with a NaN.
%
%   levels:  cell array with the value corresponding to each index. Rows
%            correspond to different conditions, while each column gives
%            a different factor.
%
%  BINS FORMAT:
%   'field_name'
%     The name of one of the fields. Each unique value in the field will
%     correspond to one label in index.
%
%   {'field_name1', 'field_name2', ...}
%     Cell array of fieldnames. There will be one label for each unique
%     combination of values of the fields.
%
%   {'filter1', 'filter2', ...}
%     Cell array of strings that will be input to inStruct to form each
%     bin.
%
%   number_of_bins
%     Integer specifying the number of bins to randomly divide events
%     into non-overlapping bins of equal length.  If events do not
%     divide evenly, unassigned events will be labeled NaN.
%
%   'overall'
%     All events will be put into one bin.
%
%   'none'
%     Each event will have its own bin.
%
%  See also patBins, modify_pattern.

% input checks
if ~exist('events', 'var')
  error('You must pass an events structure.')
elseif ~isstruct(events)
  error('events must be a structure.')
elseif ~exist('bins', 'var') || isempty(bins)
  error('You must specify how to create the bins.')
end

if iscellstr(bins)
  % conjunction of fields or set of filters
  if all(ismember(bins, fieldnames(events)))
    % multiple factors
    f = cell(1, length(bins));
    for i = 1:length(bins)
      f{i} = getStructField(events, bins{i});
    end
    % one label for each unique combination of values
    [index, levels] = make_index(f{:});
  else

    % set of filters
    index = NaN(length(events), 1);
    for i = 1:length(bins)
      thisfield = inStruct(events, bins{i});
      if any(~isnan(index(thisfield)))
        error('event subsets must not overlap.')
      end
      index(thisfield) = i;
    end
    levels = cell(length(bins), 1);
    [levels{:}] = bins{:};
  end

elseif isfield(events, bins)
  % each unique value of the field will be used
  f = getStructField(events, bins);
  uf = unique(f);
  if isnumeric(uf)
    uf = uf(~isnan(uf));
  end
  n_levels = length(uf);
  
  levels = cell(n_levels, 1);
  index = NaN(length(events), 1);
  for i = 1:n_levels
    if iscell(uf)
      val = uf{i};
    else
      val = uf(i);
    end
    index(ismember(f, val)) = i;
    levels{i} = val;
  end

elseif strcmp(bins, 'overall')
  % lump all events together
  index = ones(length(events), 1);
  
elseif strcmp(bins, 'none')
  % no binning will take place
  index = [1:length(events)]';
  
elseif ischar(bins) && ~isfield(events, bins)
  error('Field does not exist in events: %s.', bins)

elseif isnumeric(bins)
  % randomly divide up the events
  if bins < length(events)
    events_per_bin = floor(length(events) / bins);
  else
    bins = length(events);
    events_per_bin = 1;
  end

  % make the index
  index = repmat(1:bins, 1, events_per_bin);
  
  % NaN out any remainder events
  n_unlabeled = length(events) - length(index);
  index = [index NaN(1, n_unlabeled)];
  
  % shuffle
  index = randsample(index, length(index))';

else
  error('Invalid input for bins.')
end

if ~exist('levels', 'var')
  levels = unique(index);
  levels(isnan(levels)) = [];
  levels = num2cell(levels);
end

