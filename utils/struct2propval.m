function propval = struct2propval(s)
%STRUCT2PROPVAL   Convert a structure into a cell array of property-value pairs.
%   PROPVAL = STRUCT2PROPVAL(S)
%

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

fnames = fieldnames(s);
vals = struct2cell(s);
for i=1:length(fnames)
	propval{2*i-1} = fnames{i};
	propval{2*i} = vals{i};
end
