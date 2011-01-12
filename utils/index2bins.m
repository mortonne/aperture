function [bins, values] = index2bins(index)
%INDEX2BINS   Convert an index vector into bins format.
%
%  bins = index2bins(index)
%
%  INPUTS:
%    index:  numeric vector with one unique value for each group.
%
%  OUTPUTS:
%     bins:  cell array with one cell for each unique value of index.
%            Each cell contains the indices of index corresponding to
%            that value.
%
%   values:  array of values corresponding to the bins.

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
if ~isnumeric(index)
  error('index must be numeric.')
elseif ~isvector(index)
  error('index must be a vector.')
end

values = unique(index)';
values = values(~isnan(values));

bins = cell(1, length(values));
for i=1:length(values)
  bins{i} = find(index==values(i));
end

