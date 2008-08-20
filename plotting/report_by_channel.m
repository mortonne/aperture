function report_by_channel(chan,fig,file,header,title,compile)
%REPORT_BY_CHANNEL   Create a PDF report with one row per channel.
%   REPORT_BY_CHANNEL(CHAN,FIG,FILE,HEADER,TITLE,COMPILE)
%   gets channel information from the CHAN struct, and figure filenames
%   from the FIG struct, and creates a PDF report.  FIG can be a vector
%   structure; each fig makes one column in the report.
%
%   FILE indicates where to save the PDF file.  HEADER is a cell array that
%   determines the text above each column, while TITLE is a string giving
%   the title of the report.  If COMPILE is true (default is false), 
%   the program will attempt to compile the .tex file.
%
%   If figure filenames are relative (i.e. do not begin with '~' or '/'),
%   '../' is prepended to each figure filename so the report's LaTeX code 
%   knows to exit the "reports" directory.
%

% check the output file
if ~exist('file','var') || isempty(file)
  error('report_by_channel: you must specify a file to save the report in.')
end
% if this is an absolute path, make sure the parent directory exists
[parentdir,fname] = fileparts(file);
if ~isempty(parentdir) & ~exist(parentdir,'dir')
  mkdir(parentdir);
end

% default header is empty
if ~exist('header','var') || isempty(header)
  header = cell(1,length(fig));
  for i=1:length(header)
    header{i} = '';
  end
elseif ~iscell(header)
  header = {header};
end
if ~exist('title', 'var')
  title = 'Channel Report';
end
if ~exist('compile', 'var')
	compile = 0;
end

% set up table header
fullheader = {'Channel', 'Region', header{:}};

% calculate the optimal figure width
figsize = 1/(length(fig)+2);
if figsize>.2
  figsize = .2;
end
% vertical placement of text
raise = figsize*.8*.5;

% write string for each cell of the table
table = {};
for c=1:length(chan)
  n = 1;
  % channel number
  if length(chan(c).number)==1
    table{c,n} = sprintf('\\raisebox{%f\\textwidth}{%d}', raise, chan(c).number);
    n = n + 1;
  else
    table{c,n} = sprintf('\\raisebox{%f\\textwidth}{Multiple channels}', raise);
    n = n + 1;
  end
  
  % channel region
  table{c,n} = sprintf('\\raisebox{%f\\textwidth}{%s}', raise, chan(c).label);
  n = n + 1;
  
  % input the figures
  for i=1:length(fig)
    for e=1:size(fig(i).file,1)
      file = fig(i).file{e,c};
      if ~ismember(file(1), {'/', '~'}) % must be relative filename
        file = ['../' file];
      end
      table{c,n} = sprintf('\\includegraphics[width=%f\\textwidth]{%s}', figsize, file);
      n = n + 1;
    end
  end
end

% create a latex file for the report, attempt to compile
longtable(table, fullheader, file, title, compile);
