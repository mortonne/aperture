function report_by_channel(chan, fig, filename, title, compile)
%report_by_channel(dim, fig, filename, title, compile)

if ~exist('title', 'var')
  title = 'Channel Report';
end

% set up table header
header = {'Channel', 'Region'};
h = length(header) + 1;
for i=1:length(fig)
  for e=1:size(fig(i).file,1)
    header{h} = fig(i).title;
    h = h + 1;
  end
end

figsize = 1/(length(fig)+2);
raise = 6*(1/length(fig));

% write string for each cell of the table
table = {};
for c=1:length(chan)
  n = 1;
  
  if length(chan(c).number)==1
    table{c,n} = sprintf('\\raisebox{%fcm}{%d}', raise, chan(c).number);
    n = n + 1;
  else
    table{c,n} = sprintf('\\raisebox{%fcm}{Multiple channels}', raise);
    n = n + 1;
  end
  
  table{c,n} = sprintf('\\raisebox{%fcm}{%s}', raise, chan(c).label);
  n = n + 1;
  
  for i=1:length(fig)
    for e=1:size(fig(i).file,1)
      table{c,n} = sprintf('\\includegraphics[width=%f\\textwidth]{%s}', figsize, fig(i).file{e,c});
      n = n + 1;
    end
  end
end

longtable(filename, title, header, table, compile);
