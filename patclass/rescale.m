function x = rescale(x)
%RESCALE   Rescale data to range from 0 to 1.
%
%  y = rescale(x)
%
%  INPUTS:
%        x:  an [observations X variables] matrix of data. Each column
%            will be rescaled separately.
%
%  OUTPUTS:
%        y:  rescaled data.

% input checks
if ~exist('x', 'var')
  error('You must pass a matrix.')
elseif ~isnumeric(x)
  error('Data must be numeric.')
end

% rescale
x_min = min(x, [], 1);
x_range = range(x, 1);
for i=1:size(x, 2)
  x(:,i) = (x(:,i) - x_min(i)) / x_range(i);
end

