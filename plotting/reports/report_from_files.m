function pdf_file = report_from_files(res_dir, sub_dirs, report_file, ...
                                      varargin)
%REPORT_FROM_FILES   Create a report from saved figures.
%
%  Use this function to quickly create a report from figure files that
%  are organized in directories. Each subdirectory must contain figures
%  with the same names. Each column of the report will contain figures
%  from one subdirectory.
%
%  pdf_file = report_from_files(res_dir, sub_dirs, report_file)
%
%  INPUTS:
%      res_dir:  path to parent directory.
%
%     sub_dirs:  cell array of paths to directories with saved figures,
%                relative to res_dir.
%
%  report_file:  path to the file where the report will be saved.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   title - string giving a title for report. ('')
%   ext   - file extension for all the graphics files. Set to '' to
%           include all files. ('.eps')
%
%  EXAMPLE:
%   In my_dir, there are subdirectories called analysis1 and analysis2.
%   Both of these subdirectories contain graphics files called foo.eps
%   and bar.eps. Then
%
%    pdf_file = report_from_files(my_dir, {'analysis1' 'analysis2'}, ...
%                                 fullfile(my_dir, 'my_report'));
%
%   will create a report with a 2X2 table, with analysis1 in the first
%   column, and analysis2 in the second. foo will go in the first row,
%   and bar will go in the second row.

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

% options
defaults.title = '';
defaults.ext = '.eps';
params = propval(varargin, defaults);

% find the figures
file_cell = cell(1, length(sub_dirs));
names = {};
for i = 1:length(sub_dirs)
  search = fullfile(res_dir, sub_dirs{i}, ['*' params.ext]);
  d = dir(search);
  names = [names {d.name}];
  file_cell{i} = {d.name};
  for j = 1:length(file_cell{i})
    [p, name, ext] = fileparts(d(j).name);
    file_cell{i}{j} = fullfile(res_dir, sub_dirs{i}, name);
  end
end

% convert to create_report format
fig_files = cat(1, file_cell{:})';

% get row labels
row_labels = cell(1, size(fig_files, 1));
for i = 1:size(fig_files, 1)
  [p, row_labels{i}, ext] = fileparts(names{i});
  row_labels{i} = strrep(row_labels{i}, '_', ' ');
end

% create latex code for the cells
table = create_report(fig_files, row_labels);

% define the header based on the directory path
header = cell(1, length(sub_dirs));
for i = 1:length(sub_dirs)
  header{i} = strrep(sub_dirs{i}, '_', ' ');
end

longtable(report_file, table, 'header', [{''} header], ...
          'orientation', 'portrait', 'title', params.title);

pdf_file = pdflatex(report_file, 'latexdvipdf');

