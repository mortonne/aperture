function longtable(filename, table, varargin)
%LONGTABLE   Create a LaTeX longtable from Matlab data.
%
%  This script is designed to create a multipage table using LaTeX code.
%  It is particularly useful for making PDF reports of multiple figures.
%  You must figure out the proper LaTeX code to put in each cell of the
%  table; this script just handles creating the document and placing
%  your code in the table.
%
%  LaTeX will automatically break the table into as many pages as
%  needed. On each page, the first row of the table will be a header
%  that you specify.
%
%  NEW CALLING SIGNATURE:
%
%  longtable(filename, table, ...)
%
%  INPUTS:
%  filename:  path to the file that LaTeX code will be written to.
%
%     table:  cell array with a string of LaTeX code in each cell.
%
%  PARAMS:
%   header          - cell array of strings indicating a header to be
%                     placed at the top of the table on every page. ({})
%   orientation     - page orientation ('portrait' or 'landscape').
%                     ('landscape')
%   title           - title for the document. ('')
%   col_format      - format of each column. May be string (applied to
%                     all columns) or a cell array of strings with one
%                     element for each column. ('c')
%   col_width       - numeric array indicating the width of each column.
%                     May have one element for each column (any element
%                     that is NaN is ignored), or be a scalar (to be
%                     applied to all columns). Overrides col_format.
%                     ([])
%   col_width_units - units of col_width. ('\\textwidth')
%
%  OLD CALLING SIGNATURE (currently supported, but deprecated):
%
%  longtable(table, header, filename, title, landscape)
%
%  INPUTS:
%  landscape:  boolean scalar. If true (default), the page will be in
%              landscape orientation.
%
%  OUTPUTS:
%  A LaTeX file saved in filename, which you must compile to make a PDF
%  report.
%
%  If you are using the \includegraphics command to add .eps figures, use:
%  latex [filename].tex; latex [filename].tex; dvipdf [filename].dvi
%
%  If you don't have .eps files:
%  pdflatex [filename].tex; pdflatex [filename].tex
%
%  See also pdflatex, create_report.

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
if ~exist('filename', 'var')
  error('You must specify an output file.')
elseif ~exist('table', 'var')
  error('You must pass a cell array of LaTeX code for the table.')
end

% backwards compatibility
if iscellstr(filename)
  % old calling signature:
  % longtable(table, header, filename, title, landscape)
  new_table = filename;
  new_header = table;
  filename = varargin{1};
  table = new_table;
  header = new_header;
  
  if length(varargin) == 1
    varargin = {'header', header};
  elseif length(varargin) == 2
    varargin = {'header', header, 'title', varargin{2}};
  elseif length(varargin) == 3 && ...
        (islogical(varargin{3}) || ismember(varargin{3}, [0 1]))
    if varargin{3}
      orientation = 'landscape';
    else
      orientation = 'portrait';
    end
    varargin = {'header', header, 'title', varargin{2}, ...
                'orientation', orientation};
  end
end

% options
defaults.header = {};
defaults.orientation = 'landscape';
defaults.title = '';
defaults.col_width = [];
defaults.col_width_units = '\textwidth';
defaults.col_format = 'c';
params = propval(varargin, defaults);

% convenience variables
n_rows = size(table, 1);
n_cols = size(table, 2);
if length(params.header) ~= n_cols
  error('header must be the same length as the number of columns in table.')
end

% set column format
if isscalar(params.col_format)
  col_format = repmat({params.col_format}, 1, n_cols);
elseif length(col_format) == n_cols
  col_format = params.col_format;
  if any(cellfun(@isempty, col_format))
    error('Some column formats are undefined.')
  end
else
  error('Column format must be specified for each column.')
end

% if specified, set column width (overwrites format)
if ~isempty(params.col_width)
  if isscalar(params.col_width)
    params.col_width = repmat(params.col_width, 1, n_cols);
  end
  
  for i = 1:n_cols
    if isnan(params.col_width(i))
      continue
    end
    col_format{i} = strcat('p{', num2str(params.col_width(i)), ...
                           params.col_width_units, '}');
    %col_format{i} = sprintf('p{%d%s}', ...
    %                        params.col_width(i), params.col_width_units);
  end
end

% set column dividers
col_pos = '|';
for i = 1:n_cols
  col_pos = [col_pos col_format{i}];
end
col_pos = [col_pos '|'];

% open the file
fid = fopen(filename, 'w');

% preamble
fprintf(fid,'\\documentclass{report}\n');
fprintf(fid,'\\usepackage{graphicx,lscape,longtable,color,verbatim,amsmath}\n');
%fprintf(fid,'\\setlength{\\marginparsep=1pt}')
% fprintf(fid,'\\setlength{\\oddsidemargin}{-1in}\n');
% fprintf(fid,'\\setlength{\\evensidemargin}{-1in}\n');
% fprintf(fid,'\\setlength{\\topmargin}{-0.5in}\n');
% fprintf(fid,'\\setlength{\\textwidth}{7.5in}\n');
% fprintf(fid,'\\setlength{\\textheight}{10.9in}\n');
% fprintf(fid,'\\setlength{\\headheight}{0.5in}\n');
% fprintf(fid,'\\setlength{\\headsep}{-0.5in}\n');
fprintf(fid,'\\pagestyle{headings}\n');
switch params.orientation
 case 'landscape'
  %fprintf(fid,'\\usepackage[right=.25in,left=.25in,bottom=-1,top=1in]{geometry}\n');
  fprintf(fid,'\\usepackage[right=0in,left=1cm,bottom=0in,top=3.2in]{geometry}\n');
 case 'portrait'
  fprintf(fid,'\\usepackage[margin=1in,left=.5in]{geometry}\n');
end
fprintf(fid,'\n');

% start the document
fprintf(fid,'\\begin{document}\n');
if strcmp(params.orientation, 'landscape')
  fprintf(fid,'\\begin{landscape}\n');
end
fprintf(fid,'\n');

% begin the longtable
fprintf(fid,'\\begin{center}\n');
fprintf(fid,'\\begin{longtable}{%s}\n', col_pos);
fprintf(fid,'\n');

% first page title
fprintf(fid,'\\multicolumn{%d}{c}{\\textbf{%s}} \\\\\n', n_cols, params.title);

% first page table header
fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\footnotesize{\\textbf{%s}}} ', params.header{1});
for j = 2:n_cols
  fprintf(fid,'& \\multicolumn{1}{c|}{\\footnotesize{\\textbf{%s}}} ', params.header{j});
end
fprintf(fid,'\\\\ \\hline\n');
fprintf(fid,'\\endfirsthead\n');
fprintf(fid,'\n');

% title (continued)
fprintf(fid,'\\multicolumn{%d}{c}{\\textbf{%s (continued)}} \\\\\n', ...
        n_cols, params.title);

% table header (continued)
fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\textbf{%s}} ', params.header{1});
for j = 2:n_cols
  fprintf(fid,'& \\multicolumn{1}{c|}{\\textbf{%s}} ', params.header{j});
end
fprintf(fid,'\\\\ \\hline\n');
fprintf(fid,'\\endhead\n');
fprintf(fid,'\n');

% table footer
fprintf(fid,'\\hline \\multicolumn{%d}{|r|}{Continued on next page...} \\\\ \\hline\n',n_cols);
fprintf(fid,'\\endfoot\n');
fprintf(fid,'\n');

% last page table footer
fprintf(fid,'\\hline \\hline\n');
fprintf(fid,'\\endlastfoot\n');
fprintf(fid,'\n');

% write the table
for i = 1:n_rows
  for j = 1:n_cols - 1
    fprintf(fid,'%s & ', table{i,j});
  end
  fprintf(fid,'%s \\\\ \n', table{i,end});
end
fprintf(fid,'\n');

% end the longtable
fprintf(fid,'\\end{longtable}\n');
fprintf(fid,'\\end{center}\n');
fprintf(fid,'\n');

% finish the document
if strcmp(params.orientation, 'landscape')
  fprintf(fid,'\\end{landscape}\n');
end
fprintf(fid,'\\end{document}');
fprintf(fid,'\n');
fclose(fid);

