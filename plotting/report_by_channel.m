function report_by_channel(chan, fig, filename, header, title, compile, resDir)
%report_by_channel(dim, fig, filename, title, compile)

if ~exist('filename','var') || isempty(filename)
  filename = 'channel_report';
end
if ~exist('header','var') || isempty(header)
  header = {'Plot'};
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
if ~exist('resDir','var')
  [resDir,f] = fileparts(fileparts(fig.file{1}));
end

if ~exist(fullfile(resDir,'reports'),'dir')
  mkdir(fullfile(resDir,'reports'));
end

figsize = 1/(length(fig)+2);
if figsize>.2
  figsize = .2;
end
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

% set up table header
fullheader = {'Channel', 'Region', header{:}};

% set the filename of the report
reportfile = fullfile(resDir,'reports',filename);

% create a latex file for the report
longtable(table, fullheader, reportfile, title, compile);
