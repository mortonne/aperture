function longtable(table, header, filename, title)
%LONGTABLE   Create a LaTeX longtable from Matlab data.
%   LONGTABLE(TABLE,HEADER,FILENAME,TITLE,COMPILE) takes cell array
%   TABLE containing LaTeX code to be placed in each cell of the table,
%   and creates LaTeX code for that table.  HEADER is a cell array
%   that should have the same number of columns as TABLE.  The optional
%   TITLE is a string that specifies the title of the table.
%
%   The LaTeX code is saved in FILENAME.

if ~exist('compile', 'var')
  compile = 0;
end

% convenience variables
colPos = [];
numRows = size(table,1);
numCols = size(table,2);
for col=1:numCols
  colPos = [colPos,'c'];
end

if length(header)~=numCols
  error('wrong size header')
end

% open the file
fid = fopen([filename '.tex'] ,'w');

% write the header code
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
fprintf(fid,'\\begin{document}\n');
fprintf(fid,'\\begin{landscape}\n');

for page=1:size(table,3)
  % begin the longtable
  fprintf(fid,'\\begin{center}\n');
  fprintf(fid,'\\begin{longtable}{%s}\n', colPos);

  % top header
  fprintf(fid,'\\multicolumn{%d}{c}\n', numCols);
  fprintf(fid,'\\textbf{%s} \\\\\n', title);
  fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\textbf{%s}} ', header{1});
  for col=2:numCols
    fprintf(fid,'& \\multicolumn{1}{c|}{\\textbf{%s}} ', header{col});
  end
  fprintf(fid,'\\\\ \\hline\n');
  fprintf(fid,'\\endfirsthead\n');
  fprintf(fid,'\n');

  % bottom header
  fprintf(fid,'\\multicolumn{%d}{c}\n',numCols);
  fprintf(fid,'\\textbf{%s (continued)} \\\\\n',title);
  fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\textbf{%s}} ', header{1});
  for col=2:numCols
    fprintf(fid,'& \\multicolumn{1}{c|}{\\textbf{%s}} ', header{col});
  end
  fprintf(fid,'\\\\ \\hline\n');
  fprintf(fid,'\\endhead\n');

  % footer
  fprintf(fid,'\\hline \\multicolumn{%d}{|r|}{Continued on next page...} \\\\\\hline\n',numCols);
  fprintf(fid,'\\endfoot\n');
  fprintf(fid,'\\hline\n');
  fprintf(fid,'\\endlastfoot\n');
  fprintf(fid,'\n');

  % write the table
  for row=1:numRows
    for col=1:numCols-1
      fprintf(fid,'%s & ', table{row,col,page});
    end
    fprintf(fid,'%s \\\\ \n', table{row,end,page});
  end

  % end the longtable
  fprintf(fid,'\\end{longtable}\n');
  fprintf(fid,'\\end{center}\n');
  fprintf(fid,'\n');
end

% finish the document
fprintf(fid,'\\end{landscape}\n');
fprintf(fid,'\\end{document}');
fclose(fid);
