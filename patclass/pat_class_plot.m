function pat = pat_class_plot(pat, fig_name, varargin)
%PAT_CLASS_PLOT   Plot a classifier performance pattern.
%
%  Use plot_class_perf to plot classifier performance attached to a
%  pattern in a stat object. Use this function to plot a pattern that
%  contains classifier performance (created by create_perf_pattern).
%
%  pat = pat_class_plot(pat, fig_name, ...)
%
%  INPUTS:
%       pat:  pattern object containing classifier fraction correct
%             values.
%
%  fig_name:  name of the figure object to create.
%
%  OUTPUTS:
%      pat:  pattern object with an added figure object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   stat_name        - name of a stat object attached to pat. If
%                      specified, p will be loaded from stat.file, and
%                      significant regions will be shaded below each
%                      plot. ('')
%   stat_index       - index of the statistic to plot (see get_stat).
%                      (1)
%   alpha            - critical value to use when determining
%                      significance. (0.05)
%   alpha_range      - if plotting p-values, this gives the range of
%                      values to color in. alpha_range(1) gives the
%                      alpha corresponding to the darkest color in the
%                      colormap, while alpha_range(2) gives the alpha
%                      value at which to begin shading. ([0.005 0.05])
%   correctm         - method to use to correct for multiple
%                      comparisions (correction separately for each
%                      event-channel-freq). [{none} | fdr | bonferroni]
%   plot_mult_chans  - if true, all channels will be plotted on one axis.
%                      Otherwise, each channel will be plotted on a
%                      separate figure. (false)
%   perf_label       - label for the classifier performance axis.
%                      ('Classifier Performance')
%   print_input      - cell array of inputs to print to use when
%                      printing figures. ({'-depsc'})
%   res_dir          - path to the directory to save figures in. Default
%                      is the pattern's standard figures directory.

% options
defaults.stat_name = '';
defaults.stat_index = 1;
defaults.alpha = 0.05;
defaults.alpha_range = [0.005 0.05];
defaults.correctm = '';
defaults.plot_mult_chans = false;
defaults.perf_label = 'Classifier Performance';
defaults.res_dir = get_pat_dir(pat, 'reports', 'figs');
defaults.print_input = {'-depsc'};
[params, plot_params] = propval(varargin, defaults);
plot_params = propval(plot_params, struct, 'strict', false);

% load any statistics needed for plotting
if ~isempty(params.stat_name)
  stat = getobj(pat, 'stat', params.stat_name);
  p = get_stat(stat, 'p', params.stat_index);
else
  p = [];
end

% load the performance
perf = get_mat(pat);

% get the non-singleton dimensions
perf_size = size(perf);
if length(perf_size) < 4
  perf_size = [perf_size ones(1, 4 - length(perf_size))];
end
ns = perf_size > 1;

% set plotting options based on the dimensionality of the data
if ns(3) && ns(4)
  % spectrogram
  x = get_dim_vals(pat.dim, 'time');
  y = get_dim_vals(pat.dim, 'freq');
elseif ns(3)
  % performance vs. time
  x = get_dim_vals(pat.dim, 'time');
  y_label = params.perf_label;
elseif ns(4)
  % performance vs. frequency
  x = get_dim_vals(pat.dim, 'freq');
  x_label = 'Frequency (Hz)';
  y_label = params.perf_label;
  
  % need param to make x-axis log-scale
else
  error(['Both time and frequency dimensions are singleton. Plotting ' ...
         'a single point is not supported.'])
end

n_chans = perf_size(2);
chan_labels = get_dim_labels(pat.dim, 'chan');
for i = 1:n_chans  
  if params.plot_mult_chans
    this_perf = perf;
    if ~isempty(p)
      this_p = p;
    end
    if ns(3) && ns(4)
      error('Cannot plot multiple spectrograms on one figure')
    end
  else
    this_perf = perf(:,i,:,:);
    if ~isempty(p)
      this_p = p(:,i,:,:);
    end
  end
  
  % plot performance for all channels
  clf
  if ns(3)
    perfmat = permute(this_perf, [2 3 1 4]);
    if ~isempty(p)
      plot_params.mark = permute(this_p, [2 3 1 4]) < params.alpha;
    end
    plot_params.y_label = y_label;
    h = plot_perf_by_time(this_perf, x, plot_params);
  elseif ns(4)
    perfmat = permute(this_perf, [2 4 1 3]);
  end
  
  % print this figure
  if params.plot_mult_chans
    files{i} = fullfile(params.res_dir, ...
                        objfilename('fig', fig_name, pat.source));
  else
    files{i} = fullfile(params.res_dir, ...
                     objfilename('fig', fig_name, pat.source, chan_labels{i}));
  end
  print(gcf, params.print_input{:}, files{i});
end

% print this figure
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

