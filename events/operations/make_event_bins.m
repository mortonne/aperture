function labels = make_event_bins(events, bins)
%MAKE_EVENT_BINS   Divide an events structure into bins.
%
%  labels = make_event_bins(events, bins)
%
%  This function is used to create regressors for statistics and pattern
%  classification.
%
%  INPUTS:
%   events:  an events structure.
%
%     bins:  input that specifies how to divide the events structure
%            into bins (see below).
%
%  OUTPUTS:
%   labels:  a vector or cell array of strings the same length as
%            events, where each unique value indicates one bin. Events
%            that are not placed in any bin are marked with a NaN.
%
%  BINS FORMAT:
%   'field_name'
%     The name of one of the fields. Same as 
%     getStructField(events, 'field_name').
%
%    {'field_name1','field_name2',...}
%     Cell array of fieldnames. There will be one label for each unique
%     combination of values of the fields.
%
%   {'filter1','filter2',...}
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
elseif ~exist('bins', 'var')
  error('You must specify how to create the bins.')
end

if iscellstr(bins)
  % first check if each string in the cell array is a field
  if all(ismember(bins, fieldnames(events)))
    f = cell(1, length(bins));
    for i=1:length(bins)
      f{i} = getStructField(events, bins{i});
    end
    % one label for each unique combination of values
    labels = make_index(f{:});
  else
    % assume each cell contains an eventfilter
    labels = NaN(1,length(events));
    for i=1:length(bins)
      thisfield = inStruct(events, bins{i});
      labels(thisfield) = i;
    end
  end

elseif isfield(events, bins)
  % each unique value of the field will be used
  labels = getStructField(events, bins);
  if islogical(labels)
    labels = double(labels);
  end

elseif strcmp(bins, 'overall')
  % lump all events together
  labels = ones(1, length(events));
  
elseif ischar(bins) && ~isfield(events, bins)
  error('Field does not exist in events: %s.', bins)

elseif isnumeric(bins)
  % randomly divide up the events
  if bins < length(events)
    events_per_bin = floor(length(events)/bins);
  else
    bins = length(events);
    events_per_bin = 1;
  end

  % make the labels
  labels = repmat(1:bins, 1, events_per_bin);
  
  % NaN out any remainder events
  n_unlabeled = length(events) - length(labels);
  labels = [labels NaN(1, n_unlabeled)];
  
  % shuffle
  labels = randsample(labels, length(labels));

elseif strcmp(bins, 'none')
  % no binning will take place
  labels = 1:length(events);
  
else
  error('Invalid input for bins.')
end
