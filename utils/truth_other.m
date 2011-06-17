function tf = truth_other(x, dim, type)
%TRUTH_OTHER   Same as any/all, but operates along other dimensions.
%
%  tf = truth_other(x, dim, type)

x_dims = 1:ndims(x);
all_ind = repmat({':'}, 1, max([ndims(x) dim]));
%tf = false(size(x));
tf = false(1, size(x, dim));
for i = 1:size(x, dim)
  % get indices to access all elements for dim_i
  ind = all_ind;
  ind{dim} = i;
  mat = x(ind{:});
  switch type
   case 'all'
    tf(i) = all(mat(:));
   case 'any'
    tf(i) = any(mat(:));
  end
end
