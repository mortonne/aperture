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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

if ~isnumeric(X)
  error('Input must be a matrix.')
end

Y = X;

% if any variables are completely missing, use mean of other
% variables
a = all(isnan(X), 1);
if any(a)
  Y(:,a) = repmat(nanmean(X, 2), 1, nnz(a));
end

% get mean for all observations of each variable
var_means = nanmean(Y, 1);

% fix each variable
for i=1:size(X,2)
  % find missing observations
  bad_obs = isnan(Y(:,i));
  
  % set all missing observations to the mean for this variable
  Y(bad_obs,i) = var_means(i);
end

if nnz(isnan(Y)) > 0
  error('Could not remove all NaNs from X.')
end
