function pat = pat_erp(pat, fig_name, varargin)
%PAT_ERP   Make event-related potential plots and print them to disk.
%
%  Create a plot for each [event X channel X frequency] in a pattern.
%  Typically used for plotting ERPs, but can also be used for plotting
%  other values that vary over time.
%
%  pat = pat_erp(pat, fig_name, ...)
%
%  INPUTS:
%           pat:  pat object containing the pattern to be plotted.
%
%      fig_name:  string identifier for the new figure object.
%
%  OUTPUTS:
%           pat:  pat object with an added figure object.
%
%  PARAMS:
%  All fields are optional.  Default values are shown in parentheses.
%  Also see plot_erp for more plotting params.
%   event_bins       - input to make_event_bins; can be used to average
%                      over events before plotting. ('')
%   diff             - if true, the difference between event 1 and event
%                      2 will be plotted below each ERP. (false)
%   stat_name        - name of a stat object attached to pat. If
%                      specified, p will be loaded from stat.file, and
%                      significant regions will be shaded below each
%                      plot. ('')
%   stat_index       - index of the statistic to plot (see get_stat).
%                      (1)
%   alpha            - critical value to use when determining
%                      significance. (0.05)
%   correctm         - method to use to correct for multiple
%                      comparisions (correction separately for each
%                      event-channel-freq). [{none} | fdr | bonferroni]
%   y_label          - label for the y-axis. Default is 'Voltage(\muV)'
%                      if ndims(patterns) < 4, otherwise 'power'.
%   plot_mult_events - if true, all events will be plotted on one axis.
%                      Otherwise, each event will be plotted on a
%                      separate figure. (true)
%   legend           - cell array of strings labeling each event in
%                      pattern. Default is get_dim_labels(pat.dim,'ev').
%   print_input      - cell array of inputs to print to use when
%                      printing figures. ({'-depsc'})
%   mult_fig_windows - if true, each figure will be plotted in a
%                      separate window. (false)
%   res_dir          - path to the directory to save figures in. Default
%                      is the pattern's standard figures directory.
%
%  EXAMPLES:
%   % make ERP plots from a pattern and create a PDF report
%   % with one row for each channel
%   pat = pat_erp(pat, 'my_erp_figs');
%   pdf_file = pat_report(pat, 2, {'my_erp_figs'});
%
%  See also pat_plottopo, pat_report, plot_erp.

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

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name', 'var')
  fig_name = 'erp';
end

% options
defaults.event_bins = '';
defaults.diff = false;
defaults.stat_name = '';
defaults.stat_index = 1;
defaults.stat_type = 'p';
defaults.alpha = 0.05;
defaults.correctm = '';
defaults.y_label = '';
defaults.plot_mult_events = true;
defaults.show_legend = true;
defaults.legend = {};
defaults.print_input = {'-depsc'};
defaults.mult_fig_windows = false;
defaults.res_dir = get_pat_dir(pat, 'reports', 'figs');
[params, plot_params] = propval(varargin, defaults);
plot_params = propval(plot_params, struct, 'strict', false);

params.res_dir = check_dir(params.res_dir);

if ~isempty(params.event_bins)
  % apply binning (don't modify the pat object, even in the workspace)
  binned = bin_pattern(pat, ...
                       'eventbins', params.event_bins, ...
                       'save_mats', false);
  pattern = get_mat(binned);
  binned.mat = [];
else
  % just get the pattern
  pattern = get_mat(pat);
end

% set axis information
x = get_dim_vals(pat.dim, 'time');

if ~isempty(params.stat_name)
  % get the stat object
  stat = getobj(pat, 'stat', params.stat_name);
  p = get_stat(stat, 'p', params.stat_index);
  p = abs(p);
  
  % check the size
  pat_size = patsize(pat.dim);
  stat_size = size(p);
  if any(pat_size(2:ndims(p)) ~= stat_size(2:end))
    error('p must be the same size as pattern.')
  end
end

% initialize a cell array to hold all the printed figures
[n_events, n_chans, n_samps, n_freqs] = size(pattern);
if n_events > 1 && params.plot_mult_events && isempty(params.legend)
  if exist('binned', 'var')
    params.legend = get_dim_labels(binned.dim, 'ev');
  else
    params.legend = get_dim_labels(pat.dim, 'ev');
  end
end
if n_events == 3 && params.plot_mult_events
  plot_params.colors = {[0.8195 0.0588 0.1882] ...
                        [0.1804 0.1765 0.4667] ...
                        [0.1451 0.5569 0.2627] + .1};
else
  plot_params.colors = {[     0         0    1.0000] ...
                        [     0    0.5000         0] ...
                        [1.0000         0         0] ...
                        [     0    0.7500    0.7500] ...
                        [0.7500         0    0.7500] ...
                        [0.7500    0.7500         0] ...
                        [0.2500    0.2500    0.2500]};
end
if params.plot_mult_events
  n_events = 1;
end
files = cell(n_events, n_chans, 1, n_freqs);
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);

% dimension labels
chan_labels = get_dim_labels(pat.dim, 'chan');
if ndims(pattern) > 3
  freq_labels = get_dim_labels(pat.dim, 'freq');
  freq_labels = cellfun(@(x) strrep(x, ' ', '_'), freq_labels, ...
                        'UniformOutput', false);
end
if isempty(params.y_label)
  if ndims(pattern) == 4
    params.y_label = 'Power';
  else
    params.y_label = 'Voltage (\muV)';
  end
end
plot_params.y_label = params.y_label;
num_figs = prod(size(files));
fprintf('making %d ERP plots from pattern %s...\n', num_figs, pat.name);
start_fig = gcf;
n = 1;
if n_events > 1
  event_labels = get_dim_labels(pat.dim, 'ev');
end

for i = 1:n_events
  for j = 1:n_chans
    for k = 1:n_freqs
      fprintf('%d ', n)

      if params.plot_mult_events
        e = ':';
      else
        e = i;
      end

      if params.mult_fig_windows
        figure(start_fig + n - 1)
      end
      clf

      % event-related potential(s) for this channel
      erp = permute(pattern(e,j,:,k), [1 3 2 4]);

      if ~isempty(params.stat_name)
        % get significant samples
        p_samp = squeeze(p(e,j,:,k));
        alpha_fw = correct_mult_comp(p_samp, params.alpha, params.correctm);
        plot_params.mark = p_samp < alpha_fw;
      end

      % make the plot
      if ~params.diff
        h = plot_erp(erp, x, plot_params);
      else
        subplot('position', [0.175 0.375 0.75 0.6]);
        h = plot_erp(erp, x, plot_params);
        xlabel('');
        y_lab = get(gca, 'YLabel');
        y_lab_pos = get(y_lab, 'Position');
        y_lab_pos(2) = -1;
        set(y_lab, 'Position', y_lab_pos);
        set(gca, 'XTick', []);
        
        % plot the average
        pos = get(gca, 'Position');
        subplot('position', [pos(1) 0.15 pos(3) 0.2]);
        plot_erp(erp(1,:) - erp(2,:), x);
        ylabel('');
      end

      % legend
      if n_events == 1 && ~isempty(params.legend) & params.show_legend
        l = legend(h, params.legend);
        set(l, 'Location', 'NorthEast')
      end
      
      % generate the filename
      filename = base_filename;
      if n_events > 1
        filename = [filename '_' event_labels{i}];
      else
        filename = [filename '_'];
      end
      
      filename = [filename chan_labels{j}];
      if ndims(pattern) > 3
        filename = [filename '-' freq_labels{k}];
      end
      files{i,j,1,k} = fullfile(params.res_dir, filename);

      % print this figure
      set(gcf, 'PaperSize', [11 8.5]);
      print(gcf, params.print_input{:}, files{i,j,1,k});
      n = n + 1;
    end
  end
end
fprintf('\n')

% create a new fig object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);
