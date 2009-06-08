function [new_group,good_labels] = fix_regressors(group)
%FIX_REGRESSORS   Standardize regressors.
%
%  group = fix_regressors(group)
%
%  Fix regressors so their labels are one-indexed 
%  and consecutive.

% initialize the new set of regressors
new_group = cell(1,length(group));
good_labels = true(size(group{1}));

% find undefined data points
for i=1:length(group)
  if isnumeric(group{i})
    % find data points that are not labeled for this factor
    % (if not labeled, should contain NaNs)
    good_labels(isnan(group{i})) = false;

    elseif iscell(group{i}) && all(cellfun(@ischar, group{i}))
    % cell array of strings
    % empty strings = bad
    good_labels(cellfun('isempty', group{i})) = false;
  end
end

for i=1:length(group)
  % use only the data points that are labeled for
  % all factors
  group{i} = group{i}(good_labels);

  % initialize the new labels as a numeric array
  new_group{i} = NaN(size(group{i}));

  % get unique labels for this regressor
  vals = unique(group{i});
  for j=1:length(vals)
    % get the indices for this label
    if isnumeric(vals)
      % numeric array
      ind = group{i}==vals(j);
      elseif iscell(vals) && all(cellfun(@ischar, vals))
      % cell array of strings
      ind = strcmp(group{i}, vals{j});
      else
      error('run_sig_test:regressor must be a numeric array or a cell array of strings.')
    end

    % rewrite this label
    new_group{i}(ind) = j;
  end
end
