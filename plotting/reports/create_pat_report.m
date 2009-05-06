function [table,header] = create_pat_report(pat,dim,fig_names,fig_labels)
%CREATE_PAT_REPORT   Create a PDF report of figures derived from a pattern.
%
%  [table,header] = create_pat_report(pat,dim,fig_names,fig_labels)
%
%  Use this function to prepare a report with one fig object per column,
%  and a dimension label in the first column.
%
%  INPUTS:
%         pat:  a pattern object with fig objects stored in the 'fig'
%               field.
%
%         dim:  dimension to use for labeling each row of the report.
%
%   fig_names:  cell array giving the names of figure objects to
%               include. If omitted or empty, all figure objects
%               attached to pat will be used.
%
%  fig_labels:  cell array of strings giving a label for each fig
%               object. Default is fig_names.
%
%  OUTPUTS:
%       table:  cell array of LaTeX code that can be passed into
%               longtable (or similar) to create a PDF report.
%
%      header:  cell array of strings giving the header for the
%               report.

% input checks
if ~exist('pat','var')
  error('You must pass a pattern object.')
elseif ~exist('dim','var')
  error('You must specify a dimension to use as row labels.')
end
if ~exist('fig_names','var') || isempty(fig_names)
  fig_names = {pat.fig.name};
end
if ~exist('fig_labels','var') || isempty(fig_labels)
  fig_labels = fig_names;
end

% read the input dimension
[dim_name, dim_number, dim_long_name] = read_dim_input(dim);
pat_size = patsize(pat.dim);

% if we're using events as the rows, load up the events
% structure
if strcmp(dim_name, 'ev')
  pat.dim.ev = load_events(pat.dim.ev);
  if ~isfield(pat.dim.ev, 'label')
    error('events must contain a "label" field.')
  end
end

% get a cell array of figure filenames
fig_files = {};
header = {dim_long_name};
for i=1:length(fig_names)
  fig = getobj(pat, 'fig', fig_names{i});

  % check the dimensions on the filename cell array
  if size(fig.file, dim_number)~=pat_size(dim_number)
    error('The files on fig object "%s" do not match the %s dimension of pattern "%s".', ...
          fig.name, dim_name, pat.name)
  end
  
  % put the rows dimension first, then any non-singleton dims
  [files, dim_order] = fix_dim(fig.file, dim_number, 2);
  
  % add these column(s)
  fig_files = cat(2, fig_files, files);

  % set the header for these column(s)
  if ndims(files)==2
    % blank out the header for the first column
    header{1} = '';
    
    % use the labels for this dimension
    dim2_name = read_dim_input(dim_order(2));
    header = [header pat.dim.(dim2_name).label];
  else
    header{end+1} = fig_labels{i};
  end
end

% labels for the report
row_labels = {pat.dim.(dim_name).label};

% create the table
table = create_report(fig_files, row_labels);


function [y,dim_order] = fix_dim(x,dim1,n_dims)
  %FIX_DIM   Put a specified dimension first, then non-singleton,
  %          then singleton.
  %
  %  y = fix_dim(x,dim1,n_dims)
  
  % input checks
  if ~exist('n_dims','var')
    n_dims = ndims(x);
  end
  
  % find non-singleton dimensions
  s = size(x);
  d = find(s>1);

  if length(d)>n_dims
    error('Too many non-singleton dimensions.')
  end

  % if the first dim is there, remove it from the list
  d = d(d~=dim1);

  % place the first dimension at the beginning, then
  % non-singleton dimensions, then singleton
  dim_order = [dim1 d find(s==1)];

  y = permute(x, dim_order);
%endfunction