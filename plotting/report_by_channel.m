function report_by_channel(dim, fig, filename, title)
%report_by_channel(dim, fig, filename, title)

title = 'Channel Report';

% nEvents = [];
% for i=1:length(fig)
%   nEvents(i) = size(fig(i).file, 2);
% end
% if length(unique(nEvents))==1
%   equalN = 1;
% else
%   equalN = 0;
% end

% set up table header
header = {'Channel', 'Region'};
h = length(header) + 1;
for i=1:length(fig)
  for j=1:size(fig(i).file,1)
    header{h} = dim.event.label;
    h = h + 1;
  end
end

% write string for each cell of the table
table = {};
for c=1:length(dim.chan)
  n = 1;
  
  if length(dim.chan(c).number)==1
    table{c,n} = ['\raisebox{1.7cm}{' num2str(dim.chan(c).number) '}'];
    n = n + 1;
  else
    table{c,n} = ['\raisebox{1.7cm}{Multiple channels}'];
    n = n + 1;
  end
  
  table{c,n} = ['\raisebox{1.7cm}{' dim.chan(c).label '}'];
  n = n + 1;
  
  for i=1:length(fig)
    for j=1:size(fig(i).file,1)
      fig(i).file{j,c} = strrep(fig(i).file{j,c}, '~', '/Volumes/mortonne');
      table{c,n} = ['\includegraphics[width=.20\textwidth]{' fig(i).file{j,c} '}'];
      
      n = n + 1;
    end
  end
end
  
longtable(filename, title, header, table);
