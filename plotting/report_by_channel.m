function report_by_channel(chan, fig, filename, title)
%report_by_channel(dim, fig, filename, title)

if ~exist('title', 'var')
  title = 'Channel Report';
end

% set up table header
header = {'Channel', 'Region'};
h = length(header) + 1;
for i=1:length(fig)
  header{h} = fig(i).title;
  h = h + 1;
end

figsize = 1/(length(fig)+2);

% write string for each cell of the table
table = {};
for c=1:length(chan)
  n = 1;
  
  if length(chan(c).number)==1
    table{c,n} = ['\raisebox{1.7cm}{' num2str(chan(c).number) '}'];
    n = n + 1;
  else
    table{c,n} = ['\raisebox{1.7cm}{Multiple channels}'];
    n = n + 1;
  end
  
  table{c,n} = ['\raisebox{1.7cm}{' chan(c).label '}'];
  n = n + 1;
  
  for i=1:length(fig)
    table{c,n} = sprintf('\\includegraphics[width=%f\\textwidth]{%s}', figsize, fig(i).file{c});
    n = n + 1;
  end
end

longtable(filename, title, header, table);
