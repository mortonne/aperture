function erp_image_report(exp, pat_name, varargin)
%ERP_IMAGE_REPORT   Make a report with ERP images for each subject.
%
%  Make a PDF report with one row for each subject. Columns may include
%  different channels (useful when plotting voltage) or different
%  frequencies.
%
%  erp_image_report(exp, pat_name, ...)
%
%  INPUTS:
%       exp:  an experiment object.
%
%  pat_name:  name of the pattern object to plot.
%
%  PARAMS:
%   event_index - field of the events field to sort each image by.
%                 ('artifactMS')
%   scale_index - if true, the event_index will be scaled to fit the
%                 width of the image. (false)
%   chan_filter - channel filter to apply before plotting.
%                 ({'Fz' 'Cz' 'Pz' 'Oz'})
%   map_limits  - color limits for the images. ([-20 20])
%   report_name - filename for the report. ('erp_image_report')
%   title       - title to put on the report. ('ERP Images by Channel')
%   res_dir     - directory in which to save the figures and the report.
%                 (get_pat_dir(getobj(exp.subj(1),'pat',pat_name), 'reports'))
%   dist        - distribute flag for creating the plots. (0)
%   memory      - memory to allocate for processing each pattern. ('1G')
 
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

pat = getobj(exp.subj(1), 'pat', pat_name);

% options
defaults.dist = 0;
defaults.memory = '2G';
defaults.res_dir = get_pat_dir(pat, 'reports');
defaults.report_name = 'erp_image_report';
defaults.title = 'ERP Images by Channel';
[params, image_params] = propval(varargin, defaults);

% create the plots
exp.subj = apply_to_pat(exp.subj, pat_name, @pat_images, ...
                        {params.res_dir, image_params}, ...
                        params.dist, 'memory', params.memory);

% make a report with images from all subjects
report_file = fullfile(params.res_dir, params.report_name);
pdf_file = pat_report_all_subj(exp.subj, pat_name, {'erp_image'}, ...
                               'report_file', report_file, ...
                               'compile_method', 'pdflatex', ...
                               'landscape', false);

function pat = pat_images(pat, res_dir, varargin)

defaults.event_index = 'artifactMS';
defaults.scale_index = false;
defaults.chan_filter = {'Fz' 'Cz' 'Pz' 'Oz'};
defaults.map_limits = [-20 20];
params = propval(varargin, defaults);

% get the subset of channels
pat = filter_pattern(pat, 'chan_filter', params.chan_filter, ...
                     'save_mats', false);

% plot an image of each channel
if ~exist(res_dir, 'dir')
  mkdir(res_dir);
end
cd(res_dir);
fig_dir = './figs';
pat = pat_erp_image(pat, 'erp_image', ...
                    'event_index', params.event_index, ...
                    'scale_index', params.scale_index, ...
                    'map_limits', params.map_limits, ...
                    'res_dir', fig_dir);

