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
%   header      - cell array of strings the same length as fig_paths.
%                 Default is to use fig.name from each figure object.
%   title       - string title of the report. ('')
%   landscape   - whether to print in landscape or portrait. (false)
%   header_figs - vector of figure objects to place in the top row. ([])
%   header_figs_label - label for the header fig row. ('Grand Average')
%   compile_method - 'latexdvipdf' or 'pdflatex'

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

defaults.report_file = '';
[params, report_params] = propval(varargin, defaults);
report_params = propval(report_params, struct, 'strict', false);

if ~iscell(fig_names)
  fig_names = {fig_names};
end

if isempty(params.report_file)
  pat = getobj(subj(1), 'pat', pat_name);
  report_dir = get_pat_dir(pat, 'reports');
  if length(fig_names) == 1
    basename = sprintf('%s_%s', pat.name, fig_names{1});
  else
    basename = pat.name;
  end
  
  params.report_file = get_next_file(fullfile(report_dir, ...
                                              [basename '_report']));
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

if ~isfield(report_params, 'header')
  report_params.header = labels;
end
pdf_file = create_report_all_subj(subj, fig_paths, params.report_file, ...
                                  report_params);

