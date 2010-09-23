function pdf_file = pat_report(pat, dim, fig_names, varargin)
%PAT_REPORT   Create a report from pattern figures.
%
%  pdf_file = pat_report(pat, dim, fig_names, ...)
%
%  INPUTS:
%        pat:  a pattern object.
%
%        dim:  name or number of the dimension to plot along rows.
%
%  fig_names:  cell array of strings giving figure object names.
%
%  PARAMS:
%   fig_labels     - cell array of strings labeling each column of the
%                    report. ({})
%   title          - string title for the report. ('')
%   landscape      - if true, PDF will be in landscape orientation.
%                    (true)
%   compile_method - specifies how to compile the LaTeX file. See
%                    pdflatex for options. ('latexdvipdf')
%   report_file    - path to the report file to create (without file
%                    extension). Default: saved in the pattern's
%                    default reports directory as [pat.name]_report.pdf

% set options
defaults.fig_labels = {};
defaults.title = '';
defaults.landscape = true;
defaults.compile_method = 'latexdvipdf';
defaults.landscape = true;
params = propval(varargin, defaults);

if isempty(params.report_file)
  report_dir = get_pat_dir(pat, 'reports');
  cd(report_dir)
  report_file = get_next_file([pat.name '_report']);
end

[table, header] = create_pat_report(pat, dim, fig_names, params.fig_labels);

longtable(table, header, report_file, params.title, params.landscape);
pdf_file = pdflatex(report_file, params.compile_method);

