function pdf_file = pat_report(pat, dim, fig_names, report_file, varargin)
%PAT_REPORT   Create a report from pattern figures.
%
%  pdf_file = pat_report(pat, dim, fig_names, report_file, ...)

% set options
defaults.fig_labels = {};
defaults.title = '';
defaults.compile_method = 'latexdvipdf';
params = propval(varargin, defaults);

[table, header] = create_pat_report(pat, dim, fig_names, params.fig_labels);

longtable(table, header, report_file, params.title);
pdf_file = pdflatex(report_file, params.compile_method);

