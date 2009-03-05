function bins = make_bins(step_size,start,final)
%MAKE_BINS   Define the boundaries of a series of bins.
%
%  bins = make_bins(step_size,start,final)
%
%  INPUTS:
%  step_size:  size of each bin.
%
%      start:  start of the first bin.
%
%      final:  end of the last bin.
%
%  OUTPUTS:
%       bins:  [number of bins]X2 array, where bins(X,1) gives
%              the start of bin X and bins(X,2) gives the end.

% initialize
nbins = ceil((final-start)/step_size);
bins = NaN(nbins,2);

s = start;
for i=1:nbins
  % start of this bin
  bins(i,1) = s;
  
  % end of this bin
  e = s+step_size;
  bins(i,2) = e;
  
  s = e;
end
