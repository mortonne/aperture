function bin_defs = make_overlap_bins(start, finish, bin_size, step_size)
%MAKE_OVERLAP_BINS   Define overlapping bins.
%
%  bin_defs = make_overlap_bins(start, finish, bin_size, step_size)

n_bins = (finish - start - bin_size + step_size) / step_size;
s = start;
for i = 1:n_bins
  bin_defs(i,1) = s;
  
  e = s + bin_size;
  bin_defs(i,2) = e;
  
  s = s + step_size;
end
