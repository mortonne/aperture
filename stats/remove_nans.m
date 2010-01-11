function Y = remove_nans(X)
%REMOVE_NANS  Deal with missing data points.
%
%  Y = remove_nans(X)
%
%  INPUTS:
%       X:  an [observations X variables] matrix.
%
%  OUTPUTS:
%       Y:  X, with NaNs replaced with the mean for that variable across
%           all available observations. If a given variable has no
%           observations, that variable will remain all NaNs.

if ~isnumeric(X)
  error('Input must be a matrix.')
end

% get mean for all observations of each variable
var_means = nanmean(X);

% fix each variable
Y = X;
for i=1:size(X,2)
  % find missing observations
  bad_obs = isnan(X(:,i));
  
  % set all missing observations to the mean for this variable
  Y(bad_obs,i) = var_means(i);
end
