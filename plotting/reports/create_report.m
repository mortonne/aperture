function table = create_report(fig_files,row_labels)
%CREATE_REPORT   Make a LaTeX report with a table of figures.
%
%  create_report(fig_files, row_labels)
%
%  This is a wrapper for longtable. It assumes that the entire table
%  will be composed of graphics except (at most) a leftmost column 
%  containing text and a header above each column. If you need more
%  flexibility, call longtable directly.
%
%  The size of figures is automatically scaled so they take up the
%  right amount of space on the page.
%
%  INPUTS:
%  fig_files:
%  row_labels:
%  header:
%  title:

% process inputs
if ~exist('row_labels','var')
  row_labels = {};
end
if ~exist('fig_files','var')
  error('You must specify paths to graphics to include.')
end

% number of rows is defined by fig_files
n_rows = size(fig_files,1);

if ~isempty(row_labels)
  dj = 1; % delta j for adjusting column ind
  else
  dj = 0; % don't have to adjust
end

% number of cols depends on whether we have a row label
n_cols = dj + size(fig_files,2);

% sanity check
if ~isempty(row_labels) && length(row_labels)~=n_rows
  error('row_labels must be the same length as the number of rows in fig_files.')
end

% initialize the cell array that gives LaTeX code for the entire table
table = cell(n_rows, n_cols);

% calculate the optimal figure width
fig_size = 1/(size(fig_files,2)+2);
if fig_size>0.2
  fig_size = 0.2;
end

% vertical placement of text
raise = fig_size*0.8*0.5;

% write LaTeX code for each cell of the table
for i=1:n_rows
  if ~isempty(row_labels)
    % first cell should be the row label
    table{i,1} = sprintf('\\raisebox{%f\\textwidth}{%s}', raise, row_labels{i});
  end
  
  % write in the figures
  for j=1:n_cols-dj
    table{i,j+dj} = sprintf('\\includegraphics[width=%f\\textwidth]{%s}', fig_size, fig_files{i,j});
  end
end
