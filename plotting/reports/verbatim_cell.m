function c = verbatim_cell(s, width)
%VERBATIM_CELL   Write a cell of a LaTeX table for a formatted string.
%
%  c = verbatim_cell(s, width)
%
%  INPUTS:
%        s:  string to include in the cell. May contain any characters.
%            LaTeX command sequences will not be interpreted, because
%            s will be placed inside a verbatim environment.
%
%    width:  width of the cell in \textwidth units.
%
%  OUTPUTS:
%        c:  LaTeX-formatted string, suitable for placing in a cell of a
%            table.

% define the minipage start command
mini = sprintf('%s%.4f%s', '\begin{minipage}[l]{', width, '\textwidth}');

% write the cell (can't figure out how to place newlines in a string
% without using sprintf; adding a literal \n doesn't work)
c = sprintf('%s\n%s\n%s\n%s\n%s', ...
            mini, ...
            '\begin{verbatim}', ...
            s, ...
            '\end{verbatim}', ...
            '\end{minipage}');

