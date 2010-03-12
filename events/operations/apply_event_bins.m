function binned = apply_event_bins(events, bins)
%APPLY_EVENT_BINS   Apply binning to an events structure.
%
%  binned = apply_event_bins(events, bins)
%
%  INPUTS:
%   events:  an events structure.
%
%     bins:  [1 X bins] cell array. Each cell should contain indices of
%            events corresponding to one bin. May also pass an array if
%            there is just one bin.
%
%  OUTPUTS:
%   binned:  binned events structure. Any field that had the same value
%            for all events in a bin will be set. Fields that varied
%            within each bin are removed.

% input checks
if nargin < 2
  error('You must pass bins.')
elseif isnumeric(bins)
  bins = {bins};
end

fnames = fieldnames(events);

binned = struct;
for i = 1:length(bins)
  % salvage fields that have the same value for this whole bin
  for j = 1:length(fnames)
    fname = fnames{j};
    
    % getStructField will return the field in an array (if numeric)
    % or a cell array (if anything else)
    field = getStructField(events(bins{i}), fname);
    if ~(isnumeric(field) || iscellstr(field))
      % incompatible with unique; must leave this field off
      continue
    end
    
    % see if we can include this field
    uniq_field = unique(field);
    if length(uniq_field) > 1
      continue
    end

    % initialize the field if necessary
    if ~isfield(binned, fname)
      empty = cell(1, length(bins));
      [binned.(fname)] = empty{:};
    end
    
    % set the field for this bin
    binned(i).(fname) = events(bins{i}(1)).(fname);
  end
end

