function erp_report(exp, pat_name, fig_name, varargin)
%ERP_REPORT   Make a report with grand average and subject ERPs.
%
%  erp_report(exp, pat_name, fig_name, ...)
%
%  INPUTS:
%       exp:  experiment object.
%
%  pat_name:  name of a pattern object.
%
%  fig_name:  name for the created figures.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_bins  - events to average over. See bin_pattern for possible
%                 inputs. ('overall')
%   chan_filter - array of channel numbers or cell array of channel
%                 labels, indicating channels to include. ('')
%   dist        - how to evaluate the subjects. See apply_to_pat for
%                 possible inputs. (1)
%   memory      - memory to request for each job, if dist==1. ('2G')
%   res_dir     - directory in which to save figures and the report.
%                 (get_pat_dir(getobj(exp.subj(1), 'pat', pat_name),
%                  'reports'))
%   report_name - filename for the PDF report. ([fig_name '_report'])
%   title       - title for the report. ('Event-related potentials')

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
defaults.event_bins = 'overall';
defaults.event_labels = {};
defaults.chan_filter = '';
defaults.dist = 1;
defaults.memory = '2G';
defaults.res_dir = get_pat_dir(pat, 'reports');
defaults.report_name = [fig_name '_report'];
defaults.title = 'Event-related potentials';
[params, bin_params] = propval(varargin, defaults);
bin_params = propval(bin_params, struct, 'strict', false);

fig_dir = fullfile(params.res_dir, 'figs');

if ~isempty(params.chan_filter)
  exp.subj = apply_to_pat(exp.subj, pat_name, @filter_pattern, ...
                          {'chan_filter', params.chan_filter, ...
                           'save_as', 'temp', 'overwrite', true});
  pat_name = 'temp';
end

% average over events (and other dimensions if specified)
bin_params.eventbins = params.event_bins;
bin_params.eventbinlabels = params.event_labels;
bin_params.save_as = 'temp';
bin_params.overwrite = true;
exp.subj = apply_to_pat(exp.subj, pat_name, @bin_pattern, {bin_params});

% create subject ERP plots
exp.subj = apply_to_pat(exp.subj, 'temp', @pat_erp, ...
                        {fig_name, 'res_dir', fig_dir, ...
                         'plot_mult_events', false}, ...
                        params.dist, 'memory', params.memory);

% grand average ERP
pat = grand_average(exp.subj, 'temp', 'event_bins', params.event_bins, ...
                    'event_labels', params.event_labels, ...
                    'overwrite', true);
pat = pat_erp(pat, fig_name, 'res_dir', fig_dir, 'plot_mult_events', false);

% make a report with ERPs from all subjects
report_file = fullfile(params.res_dir, params.report_name);
fig = getobj(pat, 'fig', fig_name);
pdf_file = pat_report_all_subj(exp.subj, 'temp', {fig_name}, ...
                               'header_figs', fig, ...
                               'report_file', report_file, ...
                               'compile_method', 'latexdvipdf', ...
                               'landscape', true);
