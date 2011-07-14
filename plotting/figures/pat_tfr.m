function pat = pat_tfr(pat, fig_name, varargin)
%PAT_TFR   Make time-frequency representation plots.
%
%  pat = pat_tfr(pat, fig_name, ...)
%
%  INPUTS:
%       pat:  a pat object containing the pattern to be plotted.
%
%  fig_name:  string identifier for this set of figures.
%
%  OUTPUTS:
%       pat:  pat object with an added fig object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%  Values to plot
%   event_bins       - input to make_event_bins; can be used to average
%                      over events before plotting. ([])
%   diff             - boolean; if true, before plotting, take the 
%                      difference between event 1 and event 2. (false)
%   stat_name        - name of a stat object attached to pat. If
%                      specified, p will be loaded from stat.file, and
%                      only significant samples will be colored.
%                      Positive p-values will be plotted red, while
%                      negative values will be blue. ('')
%   stat_index       - index of the statistic to plot (see get_stat).
%                      (1)
%   alpha_range      - if plotting p-values, this gives the range of
%                      values to color in. alpha_range(1) gives the
%                      alpha corresponding to the darkest color in the
%                      colormap, while alpha_range(2) gives the alpha
%                      value at which to begin shading. ([0.005 0.05])
%   correctm         - method to use to correct for multiple
%                      comparisions: [ {none} | fdr | bonferroni ]
%  Plotting options
%   plot_mult_events - applies only if either time or frequency
%                      dimension is singleton. If true, all events will
%                      be plotted on one axis. Otherwise, each event
%                      will be plotted on a separate figure. (true)
%   map_limits       - limits for the z-axis of each plot. May be:
%                       'absmax'  - Absolute minimum to absolute maximum
%                                   (default)
%                       [min max] - User-specified limits
%                       []        - Use automatic scaling
%   print_input      - input to print to use when printing figures.
%                      ({'-depsc'})
%   mult_fig_windows - if true, each figure will be plotted in a
%                      separate window. (false)
%   res_dir          - path to the directory to save figures in. Default
%                      is the pattern's standard figures directory.
%  Also see plot_tfr for more plotting options.

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
  fig_name = 'tfr';
end

% backwards compatibility
if length(varargin) == 2 && isstruct(varargin{1})
  params.res_dir = varargin{2};
  varargin = varargin{1};
end

% options
defaults.event_bins = [];
defaults.diff = false;
defaults.stat_name = '';
defaults.stat_index = 1;
defaults.alpha_range = [0.005 0.05];
defaults.correctm = '';
defaults.plot_mult_events = true;
defaults.map_limits = 'absmax';
defaults.legend = {};
defaults.print_input = {'-djpeg10'};
defaults.mult_fig_windows = false;
defaults.res_dir = get_pat_dir(pat, 'reports', 'figs');
[params, plot_params] = propval(varargin, defaults);
plot_params = propval(plot_params, struct, 'strict', false);

% prep the output directory
params.res_dir = check_dir(params.res_dir);

n_events = patsize(pat.dim, 'ev');
if ~isempty(params.event_bins)
  % create bins using inputs accepted by make_event_bins
  temp = bin_pattern(pat, 'eventbins', params.event_bins, ...
                     'save_mats', false, 'verbose', false);
  pattern = get_mat(temp);
  event_labels = get_dim_labels(temp.dim, 'ev');
  n_events = patsize(temp.dim, 'ev');
  clear temp
else
  pattern = get_mat(pat);
  event_labels = get_dim_labels(pat.dim, 'ev');
end
chan_labels = get_dim_labels(pat.dim, 'chan');

n_chans = patsize(pat.dim, 'chan');

if ~isempty(params.stat_name)
  % get the stat object
  stat = getobj(pat, 'stat', params.stat_name);
  p = get_stat(stat, 'p', params.stat_index);
  
  sig = params.alpha_range(2); % threshold for significance
  max_sig = params.alpha_range(1); % color gradient will max out here
  
  if ~isempty(params.correctm)
    % correct for multiple comparisons across all samples
    sig = correct_mult_comp(abs(p(:)), sig, params.correctm);
    max_sig = correct_mult_comp(abs(p(:)), max_sig, params.correctm);
    fprintf('Corrected for multiple comparisons using %s:\n', params.correctm)
    fprintf('min alpha: %.8f\n', sig)
    fprintf('max alpha: %.8f\n', max_sig)
  end
  
  % make the colormap, set the pattern to be plotted as the
  % z-scores of the p-values
  [pattern, map, params.map_limits] = sig_colormap(p, [sig max_sig]);
  colormap(map)
else
  if params.diff
    if size(pattern,1)~=2
      error('Can only take difference if there are two event types.')
    end
    pattern = pattern(2,:,:,:) - pattern(1,:,:,:);
  end
  
  if strcmp(params.map_limits, 'absmax')
    % use absolute maximum
    absmax = max(abs(pattern(:)));
    params.map_limits = [-absmax absmax];
  end

  colormap('default')
end

% set axis information
time = get_dim_vals(pat.dim, 'time');
freq = get_dim_vals(pat.dim, 'freq');

t_sing = length(time) < 2;
f_sing = length(freq) < 2;

if (t_sing || f_sing) && params.plot_mult_events
  num_events = 1;
else
  num_events = size(pattern,1);
end
files = cell(num_events, size(pattern,2));

% make one figure per channel
n_figs = prod(size(files));
fprintf('making %d TFR plots from pattern "%s"...\n', n_figs, pat.name);

base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);

n = 1;
start_fig = gcf;
files = cell(num_events, size(pattern,2));
for i = 1:num_events
  for c = 1:size(pattern, 2)
    if num_events == 1
      fprintf('%s ', chan_labels{c})
    else
      fprintf('%d ', n)
    end

    if (t_sing || f_sing) && params.plot_mult_events
      e = ':';
    else
      e = i;
    end
    
    if params.mult_fig_windows
      figure(start_fig + n - 1)
    end
    clf

    % get the channel to plot and reorder dimensions for plot_tfr
    data = pattern(e,c,:,:);

    if ~(t_sing || f_sing)
      % make a spectrogram
      data = permute(data, [4 3 1 2]);
      plot_params.map_limits = params.map_limits;
      h = plot_tfr(data, freq, time, plot_params);
    elseif t_sing && f_sing
      error(['Cannot plot if both time and freqeuncy dimensions are ' ...
             'singleton.'])
    elseif f_sing
      % power vs. time
      data = permute(data, [1 3 4 2]);
      h = plot_erp(data, time, plot_params);
    elseif t_sing
      % power vs. frequency
      data = permute(data, [1 4 2 3]);
      h = plot_freq(data, freq, plot_params);
    end

    % legend
    if (t_sing || f_sing) && num_events == 1
      if ~isempty(params.legend)
        l = legend(h, params.legend);
      else
        l = legend(h, event_labels);
      end
      set(l, 'Location', 'NorthEast')
    end

    % generate the filename
    filename = base_filename;
    if n_events > 1 || n_chans > 1
      filename = [filename '_'];
    end
    
    if n_events > 1
      filename = [filename event_labels{i}];
    end
    
    if n_chans > 1
      if n_events > 1
        filename = [filename '-'];
      end
      filename = [filename chan_labels{c}];
    end
    files{i,c} = fullfile(params.res_dir, filename);

    % print this figure
    print(gcf, params.print_input{:}, files{i,c})
    n = n + 1;
  end
end
fprintf('\n')

% create a new fig object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);
