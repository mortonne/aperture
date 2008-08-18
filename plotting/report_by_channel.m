function report_by_channel(chan,fig,filename,header,title,compile,resDir)
%REPORT_BY_CHANNEL   Create a PDF report with one row per channel.
%   REPORT_BY_CHANNEL(CHAN,FIG,FILENAME,HEADER,TITLE,COMPILE,RESDIR)
%   gets channel information from the CHAN struct, and figure filenames
%   from the FIG struct, and creates a PDF report.  FIG can be a vector
%   structure; each fig makes one column in the report.
%
%   FILENAME sets the name of the PDF file.  HEADER is a cell array that
%   determines the text above each column, while TITLE is a string giving
%   the title of the report.  If COMPILE is true (default is false), 
%   the program will attempt to compile the .tex file.  RESDIR determines
%   the directory the file will be saved in; default is the parent directory
%   of the first fig.
%

% default filename
if ~exist('filename','var') || isempty(filename)
  filename = 'channel_report';
end

% default header is empty
if ~exist('header','var') || isempty(header)
  header = cell(1,length(fig));
  for i=1:length(header)
    header{i} = '';
  end
end
if ~iscell(header)
  header = {header};
end
if ~exist('title', 'var')
  title = 'Channel Report';
end
if ~exist('compile', 'var')
	compile = 0;
end
% default results directory is the main dir for the first fig
if ~exist('resDir','var')
  [resDir,f] = fileparts(fileparts(fig.file{1}));
end

% set up the reports directory
if ~exist(fullfile(resDir,'reports'),'dir')
  mkdir(fullfile(resDir,'reports'));
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
  table{c,n} = sprintf('\\raisebox{%f\\textwidth}{%s}', raise, chan(c).region);
  n = n + 1;
  
  % input the figures
  for i=1:length(fig)
    for e=1:size(fig(i).file,1)
      table{c,n} = sprintf('\\includegraphics[width=%f\\textwidth]{%s}', figsize, ['../' fig(i).file{e,c}]);
      n = n + 1;
    end
  end
end

% set the filename of the report
reportfile = fullfile(resDir,'reports',filename);

% create a latex file for the report
longtable(table, fullheader, reportfile, title, compile);
