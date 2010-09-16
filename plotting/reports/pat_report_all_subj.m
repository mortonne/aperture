function pdf_file = pat_report_all_subj(subj, pat_name, fig_names, report_file, ...
                                        varargin)
%PAT_REPORT_ALL_SUBJ   Create a PDF report on a pattern for all subjects.
%
%  Creates a PDF report with pattern figures, with a row for each
%  subject. Each fig object must be extended on at most one dimension
%  (e.g. an ERP for each channel); there will be a column for each, with
%  the corresponding dimension label. If there are multiple figure
%  objects, they do not need to vary along the same dimension.
%
%  pdf_file = pat_report_all_subj(subj, pat_name, fig_names, report_file, ...)
%
%  INPUTS:
%         subj:  vector of subject objects.
%
%     pat_name:  name of a pattern object.
%
%    fig_names:  string or cell array of strings containing figure names.
%
%  report_file:  path to the file to create the report in.
%
%  Additional inputs will be passed to create_report_all_subj.
%
%  OUTPUTS:
%     pdf_file:  output report PDF file.

if ~iscell(fig_names)
  fig_names = {fig_names};
end

% get the column labels
pat = getobj(subj(1), 'pat', pat_name);
labels = {};
fig_paths = cell(1, length(fig_names));
for i=1:length(fig_names)
  fig = getobj(pat, 'fig', fig_names{i});
  dim_number = find(size(fig.file) > 1);
  if length(dim_number) > 1
    error('multiple non-singleton dimensions in figure "%s".', fig_names{i})
  elseif isempty(dim_number)
    % this figure is not extended along a dimension
    these_labels = strrep(fig_names, '_', ' ');
  else
    % use this dimension's labels
    these_labels = get_dim_labels(pat.dim, dim_number);
  end
  
  labels = [labels these_labels];
  fig_paths{i} = {'pat', pat_name, 'fig', fig_names{i}};
end

pdf_file = create_report_all_subj(subj, fig_paths, report_file, ...
                                  'header', labels, varargin{:});

