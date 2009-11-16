function x = rescale(x)

x_min = min(x, [], 1);
x_range = range(x, 1);
for i=1:size(x, 2)
  x(:,i) = (x(:,i) - x_min(i)) / x_range(i);
end
