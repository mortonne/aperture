function bin_defs = make_bins(step_size, start, final)
%MAKE_BINS   Define the boundaries of non-overlapping bins.
%
%  bin_defs = make_bins(step_size, start, final)
%
%  INPUTS:
%  step_size:  size of each bin.
%
%      start:  start of the first bin.
%
%      final:  last value to be included.
%
%  OUTPUTS:
%   bin_defs:  [number_of_bins X 2] array, where bin_defs(i,1) gives the
%              start of bin i and bin_defs(i,2) gives the end.
%
%  EXAMPLE:
%  >> bin_defs = make_bins(3, 0, 7)
%  bin_defs =
%     0     3
%     3     6
%     6     9
%
%  See also apply_bins.

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

% input checks
if ~exist('step_size', 'var')
  error('You must specify a step size.')
elseif step_size <= 0
  error('Step size must be positive.')
elseif ~exist('start', 'var') || ~isnumeric(start)
  error('You must specify a start value.')
elseif ~exist('final', 'var') || ~isnumeric(final)
  error('You must specify a final value.')
end
if start >= final
  error('Final value must be greater than start value.')
end

% initialize
nbins = ceil((final - start) / step_size);
bin_defs = NaN(nbins, 2);

s = start;
for i=1:nbins
  % start of this bin
  bin_defs(i,1) = s;
  
  % end of this bin
  e = s + step_size;
  bin_defs(i,2) = e;
  
  s = e;
end
