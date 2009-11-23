function pat = pat_topoplot(pat, fig_name, params, res_dir)
%PAT_TOPOPLOT   Make topoplots and print them to disk.
%
%  pat = pat_topoplot(pat, fig_name, params, res_dir)
%
%  Create a topographical plot for each [event X time X frequency] in a
%  pattern.  Requires EEGLAB for the plotting functions, as well as a
%  channel coordinates file that can be read by readlocs.  3D headplots
%  also require a splinefile (see topoplot).
%
%  INPUTS:
%           pat:  pat object containing the pattern to be plotted.
%
%      fig_name:  string identifier for the new fig object.
%
%        params:  structure with options for plotting.  See below.
%
%       res_dir:  path to the directory to save figures in. If not
%                 specified, files will be saved in the pattern's
%                 reports/figs directory.
%
%  OUTPUTS:
%           pat:  pat object with an added fig object.
%
%  PARAMS:
%  Values to Plot
%   event_bins     - input to make_event_bins; can be used to average
%                    over events before plotting. ('')
%   time_bins      - [nbins X 2] array specifying time bins.
%                    time_bins(i,:) gives the range of ms values for
%                    bin i. ([])
%   freq_bins      - [nbins X 2] array specifying frequency bins in Hz.
%                    ([])
%   diff           - if true, the difference between events will be
%                    plotted. (false)
%   stat_name      - name of a stat object attached to pat. If
%                    specified, p will be loaded from stat.file, and
%                    significant channels will be shaded. ('')
%   map_type       - type of p-values being plotted (see sig_colormap).
%                    If not specified, type will be assumed based on the
%                    p-values.
%                    [one_way | {two_way} | two_way_signed]
%   p_range        - range of critical values to plot.  p_range(2)
%                    gives the lowest p-value that will be shaded;
%                    p_range(1) corresponds to the darkest color.
%                    ([0.005 0.05])
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
%                      readlocs. ('~/eeg/HCGSN128.loc')
%   splinefile       - headplots only: path to a spline file compatible
%                      with headplot. ('~/eeg/HCGSN128.spl')
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
%                      figures. ({})
%   mult_fig_windows - if true, each figure will be plotted in a
%                      separate window. (false)
%
%  See also create_fig, create_pat_report.

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name','var')
  fig_name = 'topo';
elseif ~ischar(fig_name)
  error('fig_name must be a string.')
end
if ~exist('params','var')
  params = struct;
elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~exist('res_dir','var') || isempty(res_dir)
  report_dir = get_pat_dir(pat, 'reports');
  cd(report_dir)
  res_dir = './figs';
elseif ~ismember(res_dir(1), {'/','.'})
  res_dir = ['./' res_dir];
end
if ~exist(res_dir,'dir')
  mkdir(res_dir)
end

% set default parameters
defaults.plot_type = 'topo';
defaults.chan_locs = '~/eeg/HCGSN128.loc';
defaults.splinefile = '~/eeg/HCGSN128.spl';
defaults.views = {[280 35], [80 35]};
defaults.plot_input = {};
defaults.map_limits = [];
defaults.print_input = {'-depsc'};
defaults.figure_prop = {};
defaults.axis_prop = {};
defaults.colorbar = true;
defaults.plot_perimeter = true;
defaults.event_bins = '';
defaults.time_bins = [];
defaults.freq_bins = [];
defaults.diff = false;
defaults.mult_fig_window = false;
defaults.stat_name = '';
defaults.p_range = [0.005 0.05];
defaults.cap_type = 'HCGSN128';
defaults.correctm = 'fdr';
defaults.correctm_scale = 'all';
defaults.map_type = '';

params = propval(params, defaults);

if length(params.views)~=2
  error('You must indicate exactly two viewpoints to plot.')
end

% load the pattern
pattern = load_pattern(pat);

if ~isempty(params.event_bins) || ~isempty(params.time_bins) || ~isempty(params.freq_bins)
  % create bins using inputs accepted by make_event_bins
  p.eventbins = params.event_bins;
  p.MSbins = params.time_bins;
  p.freqbins = params.freq_bins;

  [pat, bins] = patBins(pat, p);
  % do the averaging within each bin
  pattern = patMeans(pattern, bins);
end

pat_size = patsize(pat.dim);
if ~isempty(params.stat_name)
  % load the p-values
  stat = getobj(pat, 'stat', params.stat_name);
  load(stat.file, 'p');
  
  % if we didn't specify the type of sig map, guess!
  if isempty(params.map_type)
    if any(p(:)<0)
      params.map_type = 'two_way_signed';
    else
      params.map_type = 'two_way';
    end
  end
  
  % HACK - remove any additional p-values
  pattern = p(1,:,:,:);
  % END HACK

  if strcmp(params.correctm_scale, 'all')
    % make the colormap, set the pattern to be plotted as the
    % z-scores of the p-values
    [pattern, map, map_limits] = prep_sig_map(pattern, params.p_range, ...
                                              params.correctm, ...
                                              params.map_type, true);
  end

else
  if params.diff
    if size(pattern,1)~=2
      error('Can only take difference if there are two event types.')
    end
    pattern = pattern(2,:,:,:) - pattern(1,:,:,:);
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

files = cell(size(pattern,1), 1, size(pattern,3), size(pattern,4));
num_figs = prod(size(files));
fprintf('making %d topoplots from pattern %s...\n', num_figs, pat.name)

% one plot for each event/time/frequency
n = 1;
for e=1:size(pattern,1)
  for t=1:size(pattern,3)
    for f=1:size(pattern,4)
      fprintf('%d ', n);
      
      % get the slice to plot
      x = squeeze(pattern(e,:,t,f));
      
      if ~isempty(params.stat_name) && strcmp(params.correctm_scale, 'fig')
        % make the colormap, set the pattern to be plotted as the
        % z-scores of the p-values
        [x, map, map_limits] = prep_sig_map(x, params.p_range, ...
                                            params.correctm, ...
                                            params.map_type, true);
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
          topoplot(x, params.chan_locs, 'colormap',[1 1 1], params.plot_input{:});
        else
          topoplot(x, params.chan_locs, 'maplimits', map_limits, params.plot_input{:});
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
          edge = width*2;
          bar_width = (1-edge)/4;
          %subplot('position', [edge 0 1-edge 1])
          %set(gca, 'Color', [.8 .8 .8], 'XTick', [], 'YTick', [], 'YColor', [.8 .8 .8])
          %c = colorbar('FontSize', 16, 'Position', [edge+bar_width/2 0.1 bar_width 0.8]);
          
          % show the left
          subplot('position', [0 0 width 1]);
          headplot(x, params.splinefile,   ...
                   'colormap', map,        ...
                   'maplimits',map_limits, ...
                   'view',views{1},        ...
                   params.plot_input{:});
                   
          % show the right
          subplot('position', [width 0 width 1]);
          [h,c_temp] = headplot(x, params.splinefile, ...
                                'colormap', map,        ...
                                'maplimits',map_limits, ...
                                'view',views{2}, ...
                                'cbar', 0, ...
                                params.plot_input{:});
          set(c_temp, 'FontSize', 16, 'Position', [edge+bar_width/4 0.125 bar_width 0.7]);
        else
          % show the left
          subplot('position', [0 0 .5 1]);
          headplot(x, params.splinefile,   ...
                   'colormap', map,        ...          
                   'maplimits',map_limits, ...
                   'view',views{1},        ...
                   params.plot_input{:});
          
          % show the right
          subplot('position', [0.5 0 .5 1]);
          headplot(x, params.splinefile,   ...
                   'colormap', map,        ...          
                   'maplimits',map_limits, ...
                   'view',views{2},        ...
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
      
      % write the filename
      filename = sprintf('%s_%s_%s_e%dt%df%d', fig_name, pat.name, pat.source, e,t,f);
      files{e,1,t,f} = fullfile(res_dir, filename);
      
      % print to file
      print(gcf, params.print_input{:}, files{e,1,t,f});
      n = n + 1;
    end
  end
end
clf reset
fprintf('\n')

% create a new fig object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

function [z,map,map_limits] = prep_sig_map(p, p_range, correctm, map_type, verbose)
  if ~exist('map_type','var')
    map_type = 'two_way_signed';
  end
  if ~exist('verbose','var')
    verbose = false;
  end
  
  sig = p_range(2); % threshold for significance
  max_sig = p_range(1); % color gradient will max out here
  
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
  [z, map, map_limits] = sig_colormap(p, [max_sig sig], map_type);
%endfunction
