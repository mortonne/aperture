function longtable(filename, title, header, table, compile)
%  Creates a LaTeX table from Matlab data
%

if ~exist('compile', 'var')
  compile = 0;
end

colPos = [];
numRows = size(table,1);
numCols = size(table,2);
for col=1:numCols
  colPos = [colPos,'c'];
end

if length(header)~=numCols
  error('wrong size header')
end

fid = fopen([filename '.tex'] ,'w');
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
fprintf(fid,'\\begin{center}\n');
fprintf(fid,'\\begin{longtable}{%s}\n', colPos);
fprintf(fid,'\\multicolumn{%d}{c}\n', numCols);
fprintf(fid,'\\textbf{%s} \\\\\n', title);

fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\textbf{%s}} ', header{1});
for col=2:numCols
  fprintf(fid,'& \\multicolumn{1}{c|}{\\textbf{%s}} ', header{col});
end
fprintf(fid,'\\\\ \\hline\n');

fprintf(fid,'\\endfirsthead\n');
fprintf(fid,'\n');
fprintf(fid,'\\multicolumn{%d}{c}\n',numCols);
fprintf(fid,'\\textbf{%s (continued)} \\\\\n',title);

fprintf(fid,'\\hline \\multicolumn{1}{|c|}{\\textbf{%s}} ', header{1});
for col=2:numCols
  fprintf(fid,'& \\multicolumn{1}{c|}{\\textbf{%s}} ', header{col});
end
fprintf(fid,'\\\\ \\hline\n');

fprintf(fid,'\\endhead\n');
fprintf(fid,'\\hline \\multicolumn{%d}{|r|}{Continued on next page...} \\\\\\hline\n',numCols);
fprintf(fid,'\\endfoot\n');
fprintf(fid,'\\hline\n');
fprintf(fid,'\\endlastfoot\n');
fprintf(fid,'\n');

for row=1:numRows
  for col=1:numCols-1
    fprintf(fid,'%s & ', table{row, col});
  end
  fprintf(fid,'%s \\\\ \n', table{row, end});
end

fprintf(fid,'\\end{longtable}\n');
fprintf(fid,'\\end{center}\n');
fprintf(fid,'\n');

fprintf(fid,'\\end{landscape}\n');
fprintf(fid,'\\end{document}');
fclose(fid);

if compile
  system(['latex ' filename '.tex']);
  system(['latex ' filename '.tex']);
  system(['dvipdf ' filename '.dvi']);
  system(['open ' filename '.pdf']);
end
