function y = boxcar_filter(x, duration, dim)
%BOXCAR_FILTER   Moving average of a time-series.
%
%  y = boxcar_filter(x, duration, dim)

if nargin < 3
  if ismatrix(x) && size(x, 1) > 1 && size(x, 2) > 1
    dim = 1;
  else
    dim = min(find(size(x) > 1));
  end
end

half = round(duration / 2);

y = x;
index = repmat({':'}, 1, ndims(x));
for i = (half+1):(size(x, dim) - half)
  x_index = index;
  x_index{dim} = (i - half):(i + half);
  y_index = index;
  y_index{dim} = i;
  y(y_index{:}) = mean(x(x_index{:}), dim);
end

