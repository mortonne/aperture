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
%           observations, that variable will be replaced with the mean
%           of observation across variables.

if ~isnumeric(X)
  error('Input must be a matrix.')
end

% get mean for all observations of each variable
var_means = nanmean(X, 1);

% fix each variable
Y = X;
for i=1:size(X,2)
  % find missing observations
  bad_obs = isnan(X(:,i));
  
  % set all missing observations to the mean for this variable
  Y(bad_obs,i) = var_means(i);
end

% if any variables are completely missing, use mean of other
% variables
a = all(isnan(X));
if any(a)
  Y(:,a) = nanmean(X, 2);
end

if nnz(isnan(Y)) > 0
  error('Could not remove all NaNs from X.')
end
