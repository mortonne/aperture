function width = column_width(x, fmt)
%COLUMN_PRINT_WIDTH   Determine the width needed for a column in a table.
%
%  width = column_width(x, fmt)

if nargin < 2
  fmt = '%g';
end

if isnumeric(x)
  % convert to a cell array of strings with the provided format
  v = x;
  x = cell(1, length(v));
  for i = 1:length(x)
    x{i} = sprintf(fmt, v(i));
  end
elseif iscell(x) && ~iscellstr(x)
  v = x;
  x = cell(1, length(v));
  for i = 1:length(v)
    x{i} = sprintf(fmt, v{i});
  end
end

len = cellfun(@length, x);
width = max(len);
