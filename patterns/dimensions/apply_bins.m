function bin_inds = apply_bins(x, bin_defs)
%APPLY_BINS   Apply bins to a vector.
%
%  bin_inds = apply_bins(x, bin_defs)
%
%  Given a numeric vector and a range or set of ranges defining bin(s),
%  find the indices of the vector corresponding to each bin.
%
%  INPUTS:
%         x:  numeric vector to apply binning to.
%
%  bin_defs:  [bins X 2] matrix that defines the bins. Each row defines
%             one bin. bin_defs(i,1) and bin_defs(i,2) define the lower
%             and upper limits, respectively, of bin i. Limits are
%             inclusive, with one exception: if the upper limit of a bin
%             is equal to the lower limit of the next bin, the upper
%             limit will not be inclusive. Bins may overlap.
%
%  OUTPUTS:
%  bin_inds:  cell array of length [1 X bins] containing the indices of
%             x that correspond to each bin.
%
%  EXAMPLES:
%   % apply evenly-spaced bins
%   x = 1:10;
%   bin_defs = make_bins(2, 1, 10);
%   bin_inds = apply_bins(x, bin_defs);
%
%   % apply more complex overlapping bins
%   x = [7 2 15 13 1 14];
%   bin_defs = [1 7; 7 14; 13 15];
%   bin_inds = apply_bins(x, bin_defs);
%
%  See also make_bins.

% input checks
if ~exist('x', 'var') || ~isnumeric(x)
  error('You must pass a vector to bin.')
elseif ~isvector(x)
  error('x must be a vector.')
elseif ~exist('bin_defs', 'var') || ~isnumeric(bin_defs)
  error('You must pass bin definitions.')
elseif size(bin_defs, 2)~=2
  error('bin_defs must be a [bins X 2] matrix.')
end

n_bins = size(bin_defs, 1);
bin_inds = cell(1, n_bins);
for i=1:n_bins
  % extract the limits for this bin
  lower = bin_defs(i,1);
  upper = bin_defs(i,2);
  
  if lower > upper
    error('Bins must be increasing.')
  end
  
  % get the indices of the values that correspond to this bin
  if i~=n_bins && upper==bin_defs(i+1, 1)
    % upper limit is equal to next bin's lower limit; don't include it
    x_bin = lower <= x & x < upper;
  else
    % include the whole range
    x_bin = lower <= x & x <= upper;
  end
  bin_inds{i} = find(x_bin);
end
