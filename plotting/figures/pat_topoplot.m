function files = pat_topoplot(pat,fig_name,params,res_dir)
%PAT_TOPOPLOT   Make topoplots and print them to disk.
%
%  files = pat_topoplot(pat,fig_name,params,res_dir)
%
%  Requires EEGLAB for making cartoon or headplots.
%
%  INPUTS:
%           pat:
%
%      fig_name:
%
%        params:
%
%       res_dir:
%
%  relative_dir:
%
%  OUTPUTS:
%         files:
%
%  PARAMS:
%  Values to Plot
%   event_bins - 
%   stat_name  - 
%   p_range    - 
%   correctm   - 
%  Plotting Options
%   plot_type        - 
%   plot_input       - 
%   cap_type         - 
%   chan_locs        - 
%   map_limits       - 
%   print_input      - 
%   mult_fig_windows - 

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name','var')
  fig_name = 'topo';
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
params = structDefaults(params, ...
                        'plot_type',        'topo',                     ...
                        'chan_locs',        '~/eeg/HCGSN128.loc',       ...
                        'splinefile',       '~/eeg/HCGSN128.spl',       ...
                        'views',            {[280 35],[80 35]},         ...
                        'plot_input',       {},                         ...
                        'map_limits',       [],                         ...
                        'print_input',      {'-depsc'},                 ...
                        'figure_prop',      {},                         ...
                        'axis_prop',        {},                         ...
                        'colorbar',         true,                       ...
                        'plot_perimeter',   true,                      ...
                        'event_bins',       '',                         ...
                        'time_bins',        '',                         ...
                        'freq_bins',        '',                         ...
                        'diff',             false,                      ...
                        'mult_fig_windows', 0,                          ...
                        'stat_name',        '',                         ...
                        'p_range',          [0.005 0.05],               ...
                        'cap_type',         'HCGSN128',                 ...
                        'correctm',         'fdr',                      ...
                        'correctm_scale',   'all');

if length(params.views)~=2
  error('You must indicate exactly two viewpoints to plot.')
end

% load the pattern
pattern = load_pattern(pat);

if ~isempty(params.event_bins) || ~isempty(params.time_bins) || ~isempty(params.freq_bins)
  % create bins using inputs accepted by make_event_bins
  p = struct('field',    params.event_bins, ...
             'MSbins',   params.time_bins,  ...
             'freqbins', params.freq_bins);
  [pat, bins] = patBins(pat, p);
  % do the averaging within each bin
  pattern = patMeans(pattern, bins);
end

pat_size = patsize(pat.dim);
if ~isempty(params.stat_name)
  % load the p-values
  stat = getobj(pat, 'stat', params.stat_name);
  load(stat.file, 'p');
  
  % HACK - remove any additional p-values
  pattern = p(1,:,:,:);
  % END HACK

  if strcmp(params.correctm_scale, 'all')
    % make the colormap, set the pattern to be plotted as the
    % z-scores of the p-values
    [pattern, map, map_limits] = prep_sig_map(pattern, params.p_range, params.correctm, true);
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
        [x, map, map_limits] = prep_sig_map(x, params.p_range, params.correctm, true);
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
        figure
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

function [z,map,map_limits] = prep_sig_map(p, p_range, correctm, verbose)
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
  [z, map, map_limits] = sig_colormap(p, [max_sig sig], 'two_way_signed');
%endfunction
