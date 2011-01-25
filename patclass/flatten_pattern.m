function y = flatten_pattern(x)
%FLATTEN_PATTERN   Reshape a pattern into an [observations X variables] matrix.
%
%  y = flatten_pattern(x)

if ndims(x) <= 2
  y = x;
  return
end

xsize = size(x);
y = reshape(x, [xsize(1) prod(xsize(2:end))]);

