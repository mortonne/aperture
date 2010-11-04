function pat = pat_topoplot(pat, fig_name, varargin)
%PAT_TOPOPLOT   Make topoplots and print them to disk.
%
%  Create a topographical plot for each [event X time X frequency] in a
%  pattern.  Requires EEGLAB for the plotting functions, as well as a
%  channel coordinates file that can be read by readlocs.  3D headplots
%  also require a splinefile (see topoplot).
%
%  pat = pat_topoplot(pat, fig_name, ...)
%
%  INPUTS:
%           pat:  pat object containing the pattern to be plotted.
%
%      fig_name:  string identifier for the new fig object.
%
%        params:  structure with options for plotting.  See below.
%
%  OUTPUTS:
%           pat:  pat object with an added fig object.
%
%  PARAMS:
%  Values to Plot
%  All fields are optional.  Default values are shown in parentheses.
%  Also see plot_erp for more plotting params.
%   event_bins     - input to make_event_bins; can be used to average
%                    over events before plotting. ('')
%   diff           - if 1, will take difference between events 1 and 2
%                    before plotting; if -1, will plot difference
%                    between 2 and 1. If 0, no difference will be taken.
%                    (0)
%   stat_name      - name of a stat object attached to pat. If
%                    specified, p will be loaded from stat.file, and
%                    significant channels will be shaded. ('')
%   stat_index     - index of the statistic to plot (see get_stat).
%                    (1)
%   map_type       - type of p-values being plotted (see sig_colormap).
%                    If not specified, type will be assumed based on the
%                    p-values.
%                    [one_way | {two_way} | two_way_signed]
%   alpha_range    - range of critical values to plot.  alpha_range(1)
%                    corresponds to the darkest color; alpha_range(2)
%                    corresponds to the lowest p-value that will be
%                    shaded. ([0.005 0.05])
%   correctm       - method to use to correct for multiple comparisions.
%                    [{none} | fdr | bonferroni]
%   correctm_scale - scale at which to correct multiple comparisons.
%                    [{fig} | all]
%  Plotting Options
%   plot_type        - type of plot to make.  'topo' and 'head' use
%                      topoplot and headplot, respectively.
%                      [{topo} | head]
%   plot_input       - cell array of additional inputs to the plotting
%                      function. ({})
%   plot_perimeter   - if false, perimeter channels will be set to the
%                      middle value of the colormap to prevent color
%                      from being interpolated onto the face. (false)
%   cap_type         - string identifier of the type of electrode cap
%                      used.  Only necessary if plot_perimeter is false.
%                      See perimeter_chans. ('HCGSN128')
%   chan_locs        - path to a channel locations file compatible with
%                      readlocs. ('HCGSN128.loc')
%   splinefile       - headplots only: path to a spline file compatible
%                      with headplot. ('HCGSN128.spl')
%   views            - headplots only: camera views to use when printing
%                      headplots.  See headplot.  ({[280 35],[80 35]})
%   colorbar         - if true, a colorbar will be plotted. (true)
%   figure_prop      - cell array of property, value pairs for modifying
%                      each figure. ({})
%   axis_prop        - cell array of property, value pairs for modifying
%                      each figure's axes. ({})
%   map_limits       - range of values corresponding to the limits of
%                      the colormap. ([])
%   print_input      - cell array of inputs to use when printing
%                      figures. ({'-depsc'})
%   mult_fig_windows - if true, each figure will be plotted in a
%                      separate window. (false)
%   res_dir          - path to the directory to save figures in. Default
%                      is the pattern's standard figures directory.
%
%  See also pat_plottopo.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name', 'var')
  fig_name = 'topo';
elseif ~ischar(fig_name)
  error('fig_name must be a string.')
end

% options
defaults.plot_type = 'topo';
defaults.chan_locs = 'HCGSN128.loc';
defaults.splinefile = 'HCGSN128.spl';
defaults.views = {[280 35], [80 35]};
defaults.plot_input = {};
defaults.map_limits = [];
defaults.print_input = {'-depsc'};
defaults.figure_prop = {};
defaults.axis_prop = {};
defaults.colorbar = true;
defaults.plot_perimeter = true;
defaults.event_bins = '';
defaults.diff = 0;
defaults.mult_fig_window = false;
defaults.stat_name = '';
defaults.stat_index = 1;
defaults.alpha_range = [0.005 0.05];
defaults.cap_type = 'HCGSN128';
defaults.correctm = '';
defaults.correctm_scale = 'fig';
defaults.map_type = '';
defaults.res_dir = get_pat_dir(pat, 'reports', 'figs');
params = propval(varargin, defaults);

if length(params.views) ~= 2
  error('You must indicate exactly two viewpoints to plot.')
end

% load the pattern
if ~isempty(params.event_bins)
  % create bins using inputs accepted by make_event_bins
  temp = bin_pattern(pat, 'eventbins', params.event_bins, ...
                     'save_mats', false, 'verbose', false);
  pattern = get_mat(temp);
  event_labels = get_dim_labels(temp.dim, 'ev');
  clear temp
elseif isempty(params.stat_name)
  pattern = get_mat(pat);
  event_labels = get_dim_labels(pat.dim, 'ev');
end

if ~isempty(params.stat_name)
  % load the p-values
  stat = getobj(pat, 'stat', params.stat_name);
  pattern = get_stat(stat, 'p', params.stat_index);

  if strcmp(params.correctm_scale, 'all')
    % make the colormap, set the pattern to be plotted as the
    % z-scores of the p-values
    [pattern, map, map_limits] = prep_sig_map(pattern, params.alpha_range, ...
                                              params.correctm, true);
  end

else
  if params.diff
    if size(pattern,1) ~= 2
      error('Can only take difference if there are two event types.')
    end
    if params.diff == 1
      pattern = pattern(1,:,:,:) - pattern(2,:,:,:);
    elseif params.diff == -1
      pattern = pattern(2,:,:,:) - pattern(1,:,:,:);
    else
      error('invalid input for params.diff')
    end
  end
  
  if ~isempty(params.map_limits)
    % user-defined map limits
    map_limits = params.map_limits;
  else
    % use absolute maximum
    absmax = max(abs(pattern(:)));
    map_limits = [-absmax absmax];
  end

  colormap('default');
  map = colormap;
end

% set the peripheral channels to the neutral color
if params.plot_perimeter
  to_blank = [];
else
  to_blank = perimeter_chans(params.cap_type);
end

[n_events, n_chans, n_samps, n_freqs] = size(pattern);
if ~isempty(params.stat_name)
  n_events = 1;
end
files = cell(n_events, 1, n_samps, n_freqs);
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);
time_labels = get_dim_labels(pat.dim, 'time');
freq_labels = get_dim_labels(pat.dim, 'freq');

num_figs = prod(size(files));
fprintf('making %d topoplots from pattern %s...\n', num_figs, pat.name)

% one plot for each event/time/frequency
n = 1;
for e = 1:n_events
  for t = 1:n_samps
    for f = 1:n_freqs
      fprintf('%d ', n);
      
      % get the slice to plot
      x = squeeze(pattern(e,:,t,f));

      if ~isempty(params.stat_name) && strcmp(params.correctm_scale, 'fig')
        % make the colormap, set the pattern to be plotted as the
        % z-scores of the p-values
        [x, map, map_limits] = prep_sig_map(x, params.alpha_range, ...
                                            params.correctm, true);
      end
      
      % remove perimeter channels
      x(to_blank) = mean(map_limits);
      
      publishfig
      colormap(map)
      
      % make the plot
      switch params.plot_type
       case 'topo'
        % make the plot for this slice using the supplied function
        if all(isnan(x))
          x(:) = 1;
          topoplot(x, params.chan_locs, 'colormap',[1 1 1], ...
                   params.plot_input{:});
        else
          topoplot(x, params.chan_locs, 'maplimits', map_limits, ...
                   params.plot_input{:});
        end
        if params.colorbar
          colorbar('FontSize', 16)
        end
        
       case 'head'
        close all
        figure;
        views = params.views;
        
        if params.colorbar
          width = .43;
          edge = width * 2;
          bar_width = (1 - edge) / 4;

          % left
          subplot('position', [0 0 width 1]);
          headplot(x, params.splinefile, 'colormap', map, ...
                   'maplimits', map_limits, 'view', views{1}, ...
                   params.plot_input{:});
                   
          % right
          subplot('position', [width 0 width 1]);
          [h, c_temp] = headplot(x, params.splinefile, 'colormap', map, ...
                                 'maplimits', map_limits, 'view',views{2}, ...
                                 'cbar', 0, params.plot_input{:});
          
          % position the colorbar
          set(c_temp, 'FontSize', 16, ...
              'Position', [edge + bar_width / 4 0.125 bar_width 0.7]);
        else
          % left
          subplot('position', [0 0 .5 1]);
          headplot(x, params.splinefile, 'colormap', map, ...          
                   'maplimits', map_limits, 'view', views{1}, ...
                   params.plot_input{:});
          
          % right
          subplot('position', [0.5 0 .5 1]);
          headplot(x, params.splinefile, 'colormap', map, ...          
                   'maplimits', map_limits, 'view', views{2}, ...
                   params.plot_input{:});
        end

       otherwise
        error('Invalid plot type: %s', params.plot_type)
      end
      
      % set properties
      if ~isempty(params.axis_prop)
        set(gca, params.axis_prop{:});
      end
      if ~isempty(params.figure_prop)
        set(gcf, params.figure_prop{:});
      end
      
      % set the filename
      filename = [base_filename '_'];
      if n_events > 1
        filename = [filename strrep(event_labels{e}, ' ', '-') '_'];
      end
      if n_samps > 1
        filename = [filename strrep(time_labels{t}, ' ', '-') '_'];
      end
      if n_freqs > 1
        label = strrep(freq_labels{f}, ' ', '-');
        label = strrep(label, '.', '-');
        filename = [filename label '_'];
      end
      if strcmp(filename(end), '_')
        filename = filename(1:end-1);
      end
      files{e,1,t,f} = fullfile(params.res_dir, filename);

      % print to file
      print(gcf, params.print_input{:}, files{e,1,t,f});
      n = n + 1;
    end
  end
end
fprintf('\n')

% create a new fig object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

function [z, map, map_limits] = prep_sig_map(p, alpha_range, correctm, ...
                                             verbose)
  if ~exist('verbose', 'var')
    verbose = false;
  end
  
  % darkest color
  max_sig = alpha_range(1);
  
  % threshold for significance
  sig = alpha_range(2);
  
  if ~isempty(correctm)
    % correct for multiple comparisons across all samples
    sig = correct_mult_comp(abs(p(:)), sig, correctm);
    max_sig = correct_mult_comp(abs(p(:)), max_sig, correctm);
    if verbose
      fprintf('Corrected for multiple comparisons using %s:\n', correctm)
      fprintf('min alpha: %.8f\n', sig)
      fprintf('max alpha: %.8f\n', max_sig)
    end
  end
  
  % make the colormap, set the pattern to be plotted as the
  % z-scores of the p-values
  [z, map, map_limits] = sig_colormap(p, [sig max_sig]);

