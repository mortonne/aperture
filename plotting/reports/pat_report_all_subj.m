function pdf_file = pat_report_all_subj(subj, pat_name, fig_names, varargin)
%PAT_REPORT_ALL_SUBJ   Create a PDF report on a pattern for all subjects.
%
%  Creates a PDF report with pattern figures, with a row for each
%  subject. Each fig object must be extended on at most one dimension
%  (e.g. an ERP for each channel); there will be a column for each, with
%  the corresponding dimension label. If there are multiple figure
%  objects, they do not need to vary along the same dimension.
%
%  pdf_file = pat_report_all_subj(subj, pat_name, fig_names, ...)
%
%  INPUTS:
%         subj:  vector of subject objects.
%
%     pat_name:  name of a pattern object.
%
%    fig_names:  string or cell array of strings containing figure
%                names.
%
%  OUTPUTS:
%     pdf_file:  output report PDF file.
%
%  PARAMS:
%   report_file - path to the file to create the report in. If not
%                 specified, the report will be saved in the pattern's
%                 default reports directory as [pat.name]_report.pdf.
%  Additional inputs will be passed to create_report_all_subj.

defaults.report_file = '';
[params, report_params] = propval(varargin, defaults);
report_params = propval(report_params, struct, 'strict', false);

if isempty(params.report_file)
  pat = getobj(subj(1), 'pat', pat_name);
  report_dir = get_pat_dir(pat, 'reports');
  cd(report_dir)
  params.report_file = get_next_file([pat.name '_report']);
end

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

report_params.header = labels;
pdf_file = create_report_all_subj(subj, fig_paths, params.report_file, ...
                                  report_params);

