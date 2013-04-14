function lengths = min_z(list_properties, rejection_options)
%MIN_Z   Reject outliers in a distribution of properties.
%
%  lengths = min_z(list_properties, rejection_options)

if ~exist('rejection_options', 'var')
  rejection_options = struct;
end

% set default options
if ~isfield(rejection_options, 'measure')
  rejection_options.measure = ones(1, size(list_properties, 2));
end
if ~isfield(rejection_options, 'z')
  rejection_options.z = 3 * ones(1, size(list_properties, 2));
end
if ~isfield(rejection_options, 'stat')
  rejection_options.stat = 'iqr';
end

rejection_options.measure = logical(rejection_options.measure);

% find extreme variable-properties
switch rejection_options.stat
  case 'z'
    % subtract out the mean
    zs = list_properties - ...
         repmat(mean(list_properties, 1), size(list_properties, 1), 1);
    
    % divide by the standard deviation
    zs = zs ./ repmat(std(zs, [], 1), size(list_properties, 1), 1);

    % missing values have a z-score of 0
    zs(isnan(zs)) = 0;

    % for each variable, find properties with a high absolute z-score
    all_l = abs(zs) > repmat(rejection_options.z, size(list_properties, 1), 1);
  case 'iqr'
    % rather than using standard deviation, use a non-parametric measure
    % of spread that is more robust to extreme values, skew
    
    % get quartiles 1 and 3
    q1 = prctile(list_properties, 25, 1);
    q3 = prctile(list_properties, 75, 1);
    iqr = q3 - q1;
    
    % find outliers, using a multiple of the interquartile range to set
    % thresholds
    low_thresh = q1 - (iqr .* rejection_options.z);
    low = list_properties < repmat(low_thresh, [size(list_properties, 1) 1]);
    high_thresh = q3 + (iqr .* rejection_options.z);
    high = list_properties > repmat(high_thresh, [size(list_properties, 1) 1]);
    all_l = low | high;
end
    
% a variable is excluded if any properties are too extreme. Why is this
% called lengths?? This is a logical array
lengths = any(all_l(:,rejection_options.measure), 2);