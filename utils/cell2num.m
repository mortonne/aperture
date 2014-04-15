function m = cell2num(c)
%CELL2NUM   Convert a cell array of scalars to an array.
%
%  m = cell2num(c)
%
%  If a cell array contains only scalars, this will create an array
%  with the contents of the cell array.  In other words:
%   c{i,j,k...} = m(i,j,k...)
%
%  This is similar to cell2mat, but only works on scalar contents and
%  works even if the cell contents are not numeric. Cell contents must
%  be concatenatable (i.e. same type, and if struct, must have the same
%  fields).
%
%  EXAMPLES:
%   c = num2cell(magic(4));
%   m = cell2num(c);
%
%   c = {struct('a',1), struct('a',NaN); struct('a','value'), struct('a',[])};
%   s = cell2num(c);
%
%  See also num2cell.

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

if all(cellfun(@isempty, c))
  m = [];
  return
end

m = reshape([c{:}], size(c));

