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

m = reshape([c{:}], size(c));

