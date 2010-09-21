function bin_inds = apply_bins(x, bin_defs, inclusive)
%APPLY_BINS   Apply bins to a vector.
%
%  bin_inds = apply_bins(x, bin_defs, inclusive)
%
%  INPUTS:
%          x:  vector to apply binning to.
%
%   bin_defs:  [bins X 2] matrix that defines the bins. Each row defines
%              one bin. bin_defs(i,1) and bin_defs(i,2) define the upper
%              and lower limits, respectively, of bin i.
%
%  inclusive:  if true, all bins will be inclusive; if false, all bins
%              will be inclusive only on the lower limit. If not
%              specified, all limits will be inclusive, with one
%              exception: if the upper limit of a bin is equal to the
%              lower limit of the next bin, the upper limit will not be
%              inclusive.
%
%  OUTPUTS:
%  bin_inds:  cell array of length [1 X bins] containing the indices of
%             x that correspond to each bin.
%
%  EXAMPLE:
%   >> x = [7 1 15 13 2 14];
%   >> bin_defs = [1 7; 7 13; 13 15];
%   >> bin_inds = apply_bins(x, bin_defs);
%   x(bin_inds{1}) % [1 2]
%   x(bin_inds{2}) % 7
%   x(bin_inds{3}) % [15 13 14]

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
if ~exist('inclusive', 'var')
  inclusive = false;
  auto = true;
else
  auto = false;
end

n_bins = size(bin_defs, 1);
bin_inds = cell(1, n_bins);
for i=1:n_bins
  % extract the limits for this bin
  lower = bin_defs(i,1);
  upper = bin_defs(i,2);
  
  % get the indices of the values that correspond to this bin
  if (auto && i~=n_bins && upper==bin_defs(i+1, 1)) || (~auto && ~inclusive)
    % upper limit is equal to next bin's lower limit; don't include it
    x_bin = lower <= x & x < upper;
  else
    % include the whole range
    x_bin = lower <= x & x <= upper;
  end
  bin_inds{i} = find(x_bin);
end
