function pat = pat_topoplot_fieldtrip(pat, fig_name, varargin)
%PAT_TOPOPLOT_FIELDTRIP   Make topoplots and print them to disk.
%
%  pat = pat_topoplot_fieldtrip(pat, fig_name, varargin)
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
%      
%  OUTPUTS:
%           pat:  pat object with an added fig object.
%
%  PARAMS:
%        res_dir:  path to the directory to save figures in. If not
%                 specified, files will be saved in the pattern's
%                 reports/figs directory.
%
%  Values to Plot
%   event_bins     - input to make_event_bins; can be used to average
%                    over events before plotting. ('')
%   event_labels   - cell array of strings with labels for each event/
%                    event_bin. ({})
%   diff           - if true, the difference between events will be
%                    plotted. (false)
%   stat_name      - name of a stat object attached to pat. If
%                    specified, p will be loaded from stat.file, and
%                    significant channels will be shaded. ('')
%   stat_index     - index of the statistic to plot (see get_stat).
%                    (1)
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
%   alpha          - critical value to use when determining
%                    significance. (0.05)
%   mark           - logical mask of which channel-timepoints to
%                    mark black as being in a significant fieldtrip cluster
%   mark_pos       - logical mask of which channel-timepoints to
%                    mark red as being in a significant positive fieldtrip cluster
%   mark_neg       - logical mask of which channel-timepoints to
%                    mark blue as being in a significant negative fieldtrip cluster
%   head_markchans - logical, should we mark significant channels (true)
%
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
%                      readlocs. ('~/matlab/eeg_ana/resources/HCGSN128.loc')
%   splinefile       - headplots only: path to a spline file compatible
%                      with headplot. ('~/matlab/eeg_ana/resources/HCGSN128.spl')
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
%if ~exist('params','var')
%  params = struct;
%elseif ~isstruct(params)
%  error('params must be a structure.')
%end
%zach commented this out, added default
%if ~exist('res_dir','var') || isempty(res_dir)
%  report_dir = get_pat_dir(pat, 'reports');
%  cd(report_dir)
%  res_dir = './figs';
%elseif ~ismember(res_dir(1), {'/','.'})
%  res_dir = ['./' res_dir];
%end
%if ~exist(res_dir,'dir')
%  mkdir(res_dir)
%end

% set default parameters
defaults.plot_type = 'head';
defaults.chan_locs = '~/matlab/eeg_ana/resources/HCGSN128.loc';
defaults.splinefile = '~/matlab/eeg_ana/resources/HCGSN128.spl';
defaults.views = {[280 35], [80 35]};
defaults.plot_input = {};
defaults.map_limits = [];
%defaults.print_input = {'-depsc'};
defaults.print_input = {'-djpeg50'};
defaults.figure_prop = {};
defaults.axis_prop = {};
defaults.colorbar = true;
defaults.plot_perimeter = true;
defaults.event_bins = '';
defaults.event_labels = {};
defaults.diff = false;
defaults.mult_fig_window = false;
defaults.stat_name = '';
defaults.p_range = [0.005 0.05];
defaults.cap_type = 'HCGSN128';
defaults.stat_index = 1;
defaults.stat_type = 'p';
defaults.alpha = 0.05;
defaults.correctm = '';
defaults.correctm_scale = 'all';
defaults.map_type = '';
defaults.mark = [];
defaults.mark_pos = [];
defaults.mark_neg = [];
defaults.head_markchans = true;
defaults.res_dir = get_pat_dir(pat, 'reports', 'figs');

params = propval(varargin, defaults);

params.res_dir = check_dir(params.res_dir);

if length(params.views)~=2
  error('You must indicate exactly two viewpoints to plot.')
end

if ~isempty(params.event_bins)
  % apply binning (don't modify the pat object, even in the workspace)
  temp = bin_pattern(pat, ...
                     'eventbins', params.event_bins, ...
                     'save_mats', false);
  pattern = get_mat(temp);
  
  if isempty(params.event_labels)
    % try to grab labels from the events
    labels = get_dim_labels(temp.dim, 'ev');
    if length(unique(labels)) == length(labels)
      params.event_labels = labels;
    end
  end
  
  clear temp
else
  % just get the pattern
  pattern = get_mat(pat);
end

mark = false(size(pattern));
if isempty(params.mark_pos)
  params.mark_pos = mark;
end
if isempty(params.mark_neg)
  params.mark_neg = mark;
end

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
    pattern = pattern(1,:,:,:) - pattern(2,:,:,:);
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

% cell array to hold paths to printed figures
n_freq = size(pattern, 4);
%files = cell(1, 1, 1, n_freq);
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);

if n_freq > 1
  fprintf('Making %d plots...', n_freq)
  freq = get_dim(pat.dim, 'freq');
end

files = cell(size(pattern,1), 1, size(pattern,3), size(pattern,4));
num_figs = prod(size(files));
fprintf('making %d topoplots from pattern %s...\n', num_figs, pat.name)


eloc = readlocs(params.chan_locs);
n_chans = size(pattern, 2);


% one plot for each event/time/frequency
n = 1;
for e=1:size(pattern,1)
  for t=1:size(pattern,3)
    for f=1:size(pattern,4)
      fprintf('%d ', n);
      
      % get the slice to plot
      x = squeeze(pattern(e,:,t,f));
      mark_chans = find(abs(squeeze(mark(e,:,t,f))) == 1);
      mark_chans_pos = find(abs(squeeze(params.mark_pos(e,:,t,f))) == 1);
      mark_chans_neg = find(abs(squeeze(params.mark_neg(e,:,t,f))) == 1);
      
      if ~isempty(params.stat_name) && strcmp(params.correctm_scale, 'fig')
        % make the colormap, set the pattern to be plotted as the
        % z-scores of the p-values
        [x, map, map_limits] = prep_sig_map(x, params.p_range, ...
                                            params.correctm, ...
                                            params.map_type, true);
      end
      
      % remove perimeter channels
      x(to_blank) = mean(map_limits);
      
      clf
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
          if ~isempty(mark_chans) || ~isempty(mark_chans_pos) || ...
                ~isempty(mark_chans_neg)
            if ~isempty(mark_chans)
              % topoplot with emarker2 here
              topoplot(x, params.chan_locs, 'maplimits', map_limits, ...
                       'emarker2', {[mark_chans], 'o', 'k', 10, 1}, ...
                       params.plot_input{:});
            else
              if ~isempty(mark_chans_pos) && ~isempty(mark_chans_neg)
              % topoplot with emarker2 and emarker3 here
              topoplot_fieldtrip(x, params.chan_locs, 'maplimits', map_limits, ...
                           'emarker2', {[mark_chans_pos], 'o', 'r', 10, 1}, ...
                           'emarker3', {[mark_chans_neg], 'o', 'b', 10, 1}, ...
                           params.plot_input{:});
              else
                % topoplot with emarker2 here
                %need to add a condition where just mark_chans is
                %used
                %to do nov 9 2010
                if ~isempty(mark_chans_pos)
                  mark_chans = mark_chans_pos;
                  topoplot(x, params.chan_locs, 'maplimits', map_limits, ...
                           'emarker2', {[mark_chans], 'o', 'r', 10, 1}, ...
                           params.plot_input{:});
                elseif ~isempty(mark_chans_neg)
                  mark_chans = mark_chans_neg;
                  topoplot(x, params.chan_locs, 'maplimits', map_limits, ...
                           'emarker2', {[mark_chans], 'o', 'b', 10, 1}, ...
                           params.plot_input{:});
                end
              end
            end
          else
            topoplot(x, params.chan_locs, 'maplimits', map_limits, ...
                     params.plot_input{:});
          end
        end
        if params.colorbar
          colorbar('FontSize', 16)
        end
        
        case 'head'
        close all
        figure;
        views = params.views;
        
        sig_chans_mask = [];
        if params.head_markchans
          m_pos = abs(squeeze(params.mark_pos(e,:,t,f))) == 1;
          m_neg = abs(squeeze(params.mark_neg(e,:,t,f))) == 1;
          sig_chans_mask = m_pos+(m_neg.*-1);
        end
        
        if params.colorbar
          width = .43;
          edge = width*2;
          bar_width = (1-edge)/4;
          %subplot('position', [edge 0 1-edge 1])
          %set(gca, 'Color', [.8 .8 .8], 'XTick', [], 'YTick', [], 'YColor', [.8 .8 .8])
          %c = colorbar('FontSize', 16, 'Position', [edge+bar_width/2 0.1 bar_width 0.8]);
          
          % show the left
          subplot('position', [0 0 width 1]);
          headplot_fieldtrip(x, params.splinefile,   ...
                   'colormap', map,        ...
                   'maplimits',map_limits, ...
                   'view',views{1},        ...
                   'plotchans',sig_chans_mask,    ...
                   params.plot_input{:});
                   
          % show the right
          subplot('position', [width 0 width 1]);
          [h,c_temp] = headplot_fieldtrip(x, params.splinefile, ...
                                'colormap', map,        ...
                                'maplimits',map_limits, ...
                                'view',views{2}, ...
                                'cbar', 0, ...
                                'plotchans',sig_chans_mask,    ...                                    
                                 params.plot_input{:});
          set(c_temp, 'FontSize', 18, 'Position', [edge+bar_width/4 0.125 bar_width 0.7]);
        else
          % show the left
          subplot('position', [0 0 .5 1]);
          headplot_fieldtrip(x, params.splinefile,   ...
                   'colormap', map,        ...          
                   'maplimits',map_limits, ...
                   'view',views{1},        ...
                   'plotchans',sig_chans_mask,    ...                                    
                    params.plot_input{:});
          
          % show the right
          subplot('position', [0.5 0 .5 1]);
          headplot_fieldtrip(x, params.splinefile,   ...
                   'colormap', map,        ...          
                   'maplimits',map_limits, ...
                   'view',views{2},        ...
                   'plotchans',sig_chans_mask,    ...                                    
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
      files{e,1,t,f} = fullfile(params.res_dir, filename);
      
      % print to file
      print(gcf, params.print_input{:}, files{e,1,t,f});
      n = n + 1;
    end
  end
end
%clf reset
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
