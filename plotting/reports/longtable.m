function longtable(table, header, filename, title, landscape)
%LONGTABLE   Create a LaTeX longtable from Matlab data.
%
%  longtable(table, header, filename, title)
%
%  This script is designed to create a multipage table using LaTeX code.
%  It is particularly useful for making PDF reports of multiple figures.
%  You must figure out the proper LaTeX code to put in each cell of the
%  table; this script just handles creating the document and placing
%  your code in the table.
%
%  LaTeX will automatically break the table into as many pages as needed.
%  On each page, the first row of the table will be a header that you specify.
%
%  INPUTS:
%      table:  cell array with a string of LaTeX code in each cell.
%
%     header:  cell array of strings of the same length as the number of
%              columns in table. The header will be displayed in the first
%              row of the table on each page.
%
%   filename:  path to the file that LaTeX code will be written to.
%
%      title:  optional string title for the table.
%
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
%  See also create_report.

if ~exist('landscape','var')
  landscape = true;
end
if ~exist('title','var')
  title = '';
end
if ~exist('filename','var')
  error('You must specify an output file.')
elseif ~exist('header','var')
  error('You must pass a header cell array.')
elseif ~exist('table','var')
  error('You must pass a cell array of LaTeX code for the table.')
end

% convenience variables
n_rows = size(table,1);
n_cols = size(table,2);
if length(header)~=n_cols
  error('header must be the same length as the number of columns in table.')
end

% set the column formatting
col_pos = '|';
for col=1:n_cols
  col_pos = [col_pos 'c'];
end
col_pos = [col_pos '|'];

% open the file
fid = fopen(filename,'w');

% preamble
fprintf(fid,'\\documentclass{report}\n');
fprintf(fid,'\\usepackage{graphicx,lscape,longtable,color}\n');
fprintf(fid,'\\setlength{\\oddsidemargin}{-0.5in}\n');
fprintf(fid,'\\setlength{\\evensidemargin}{-0.5in}\n');
fprintf(fid,'\\setlength{\\topmargin}{-0.25in}\n');
fprintf(fid,'\\setlength{\\textwidth}{7.5in}\n');
fprintf(fid,'\\setlength{\\textheight}{10.9in}\n');
fprintf(fid,'\\setlength{\\headheight}{0.5in}\n');
fprintf(fid,'\\setlength{\\headsep}{-0.5in}\n');
fprintf(fid,'\\pagestyle{headings}\n');
fprintf(fid,'\n');

% start the document
fprintf(fid,'\\begin{document}\n');
if landscape
  fprintf(fid,'\\begin{landscape}\n');
end
fprintf(fid,'\n');

% begin the longtable
fprintf(fid,'\\begin{center}\n');
fprintf(fid,'\\begin{longtable}{%s}\n', col_pos);
fprintf(fid,'\n');

% first page title
fprintf(fid,'\\multicolumn{%d}{c}{\\textbf{%s}} \\\\\n', n_cols, title);

% first page table header
fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\textbf{%s}} ', header{1});
for j=2:n_cols
  fprintf(fid,'& \\multicolumn{1}{c|}{\\textbf{%s}} ', header{j});
end
fprintf(fid,'\\\\ \\hline\n');
fprintf(fid,'\\endfirsthead\n');
fprintf(fid,'\n');

% title (continued)
fprintf(fid,'\\multicolumn{%d}{c}{\\textbf{%s (continued)}} \\\\\n', n_cols, title);

% table header (continued)
fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\textbf{%s}} ', header{1});
for j=2:n_cols
  fprintf(fid,'& \\multicolumn{1}{c|}{\\textbf{%s}} ', header{j});
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
for i=1:n_rows
  for j=1:n_cols-1
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
if landscape
  fprintf(fid,'\\end{landscape}\n');
end
fprintf(fid,'\\end{document}');
fprintf(fid,'\n');
fclose(fid);
