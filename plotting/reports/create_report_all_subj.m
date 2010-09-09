function pdf_file = create_report_all_subj(subj, fig_paths, report_file, varargin)
%CREATE_REPORT_ALL_SUBJ   Create a report with one row for each subject.
%
%  pdf_file = create_report_all_subj(subj, fig_paths, report_file, ...)
%
%  INPUTS:
%         subj:  a vector of subject objects.
%
%    fig_paths:  cell array of paths to fig objects in 
%                {obj_type, obj_name, sub_obj_type, sub_obj_name, ...} form.
%
%  report_file:  path to the file to create the report (without .tex).
%                Default is:
%                 fullfile(get_pat_dir(pat, 'reports'), pat.name)
%
%  OUTPUT:
%     pdf_file:  filename of the new PDF report.
%
%  PARAMS:
%   header      - cell array of strings the same length as fig_paths.
%                 Default is to use fig.name from each figure object.
%   title       - string title of the report. ('')
%   landscape   - whether to print in landscape or portrait. (false)
%   header_figs - vector of figure objects to place in the top row. ([])
%   header_figs_label - label for the header fig row. ('Grand Average')
%   compile_method - 'latexdvipdf' or 'pdflatex'

% input checks
if ~exist('report_file', 'var') || isempty(report_file)
  pat = getobj(subj(1), fig_paths{1}{1:2});
  report_file = fullfile(get_pat_dir(pat, 'reports'), pat.name);
end

% default params
f_header_fix = @(x)strrep(x{end}, '_', ' ');
defaults.header = cellfun(f_header_fix, fig_paths, 'UniformOutput', false);
defaults.title = '';
defaults.landscape = false;
defaults.header_figs = [];
defaults.header_figs_label = 'Grand Average';
defaults.compile_method = 'latexdvipdf';

params = propval(varargin, defaults);

% get all figure files
fig_files = {};
for i=1:length(fig_paths)
  figs = getobjallsubj(subj, fig_paths{i});
  
  if ~isvector(figs(1).file)
    error('Each figure object must contain a scalar or vector of figure files.')
  end
  
  if size(figs(1).file, 1) > 1
    % event is non-singleton; create multiple columns for this fig object
    these_fig_files = cat(2, figs.file)';
  else
    % one row per subject; columns are whatever non-singleton dimension
    these_fig_files = cat(1, figs.file);
  end
  fig_files = [fig_files these_fig_files];
end
if ~isempty(params.header_figs)
  fig_files = [[params.header_figs.file]'; fig_files];
end

% set row and column labels
row_labels = {subj.id};
if ~isempty(params.header_figs)
  row_labels = [{params.header_figs_label} row_labels];
end
if length(params.header)==1
  params.header = repmat(params.header, 1, size(fig_files, 2));
end
header = ['Subject' params.header];

% create the report
table = create_report(fig_files, row_labels);
longtable(table, header, report_file, params.title, params.landscape);

% compile
pdf_file = pdflatex(report_file, params.compile_method);

