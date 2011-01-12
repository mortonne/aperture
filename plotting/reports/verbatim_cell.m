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

