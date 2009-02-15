function table = create_report(fig_files,row_labels)
%CREATE_REPORT   Make a LaTeX report with a table of figures.
%
%  table = create_report(fig_files, row_labels)
%
%  This function is designed to streamline the use of longtable. It assumes 
%  that the entire table will be composed of graphics except (at most) a 
%  leftmost column containing text and a header above each column.
%
%  The size of figures is automatically scaled so they take up the
%  right amount of space on the page.
%
%  INPUTS:
%   fig_files:  cell array of paths to graphics files to be inserted
%               in the table. The file formats can be anything recognized
%               by the LaTeX \includegraphics command.
%
%  row_labels:  optional cell array of strings to label each row of
%               the table. Must be the same length as the number of rows
%               in fig_files.
%
%  OUTPUTS:
%       table:  cell array of strings containing LaTeX code. To create a
%               LaTeX document from this, use longtable.
%
%  EXAMPLE:
%   To make a document with the following table, where *.eps are saved figures:
%
%                             Subject 1         Subject 2
%    Event Related Potential  (erp_subj1.eps)   (erp_subj2.eps)
%    Spectrogram              (spec_subj1.eps)  (spec_subj2.eps)
%
%   % first make a cell array of LaTeX code
%   fig_files = {'erp_subj1.eps', 'erp_subj2.eps'
%                'spec_subj1.eps', 'spec_subj2.eps'};
%   row_labels = {'Event Related Potential', 'Spectrogram'};
%   table = create_report(fig_files, row_labels);
%
%   % make a document with this table
%   header = {'', 'Subject 1', 'Subject 2'};
%   output_file = 'erp_spec.tex';
%   longtable(table, header, output_file);
%
%  See also longtable.

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
