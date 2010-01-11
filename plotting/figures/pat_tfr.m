function pat = pat_tfr(pat,fig_name,params,res_dir)
%PAT_TFR   Make time-frequency representation plots and print them to disk.
%
%  pat = pat_tfr(pat, fig_name, params, res_dir)
%
%  INPUTS:
%           pat:  a pat object containing the pattern to be plotted.
%
%      fig_name:  string identifier for this set of figures.
%
%        params:  structure with options for plotting. See below.
%
%       res_dir:  path to the directory to save figures in. If not
%                 specified, files will be saved in the pattern's
%                 reports/figs directory.
%
%  OUTPUTS:
%           pat:  pat object with an added fig object.
%
%  PARAMS:
%  Values to plot
%   event_bins       - input to make_event_bins; can be used to average
%                      over events before plotting
%   diff             - boolean; if true, before plotting, take the 
%                      difference between event 1 and event 2. Default: false
%   stat_name        - name of a stat object attached to pat. If
%                      specified, p will be loaded from stat.file, and
%                      only significant samples will be colored. Positive
%                      p-values will be plotted red, while negative values
%                      will be blue.
%   alpha_range      - if plotting p-values, this gives the range of values
%                      to color in. alpha_range(1) gives the alpha corresponding
%                      to the darkest color in the colormap, while alpha_range(2)
%                      gives the alpha value at which to begin shading.
%                      Default: [0.005 0.05]
%   correctm         - method to use to correct for multiple comparisions:
%                      [ {none} | fdr | bonferroni ]
%  Plotting options
%   plot_mult_events - applies only if either time or frequency
%                      dimension is singleton. If true, all events will
%                      be plotted on one axis. Otherwise, each event
%                      will be plotted on a separate figure. (true)
%   map_limits       - limits for the z-axis of each plot: [z-min,z-max].
%                      Default: -(absolute maximum) to (absolute maximum)
%   print_input      - input to print to use when printing figures.
%                      Default: {'-depsc'}
%   mult_fig_windows - if true, each figure will be plotted in a separate
%                      window. Default: false
%   Also see plot_tfr for more plotting options.

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name','var')
  fig_name = 'tfr';
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
                        'map_limits',       [],       ...
                        'print_input',      {'-depsc'}, ...
                        'event_bins',       '',       ...
                        'plot_mult_events', true,     ...                        
                        'diff',             false,    ...
                        'mult_fig_windows', false,    ...
                        'stat_name',        '',       ...
                        'alpha_range',          [0.005 0.05], ...
                        'correctm',         '');

if ~isempty(params.event_bins)
  % create bins using inputs accepted by make_event_bins
  p = [];
  p.eventbins = params.event_bins;
  p.save_mats = false;
  pattern = get_mat(modify_pattern(pat, p));
else
  pattern = get_mat(pat);
end

if ~isempty(params.stat_name)
  % get the stat object
  stat = getobj(pat, 'stat', params.stat_name);
  load(stat.file, 'p');

  % HACK - remove any additional p-values
  p = p(1,:,:,:);
  % END HACK
  
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
  [pattern, map, params.map_limits] = sig_colormap(p, [max_sig sig], 'two_way_signed');
  colormap(map)
else
  if params.diff
    if size(pattern,1)~=2
      error('Can only take difference if there are two event types.')
    end
    pattern = pattern(2,:,:,:) - pattern(1,:,:,:);
  end
  
  if isempty(params.map_limits)
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
fprintf('making %d TFR plots from pattern %s...\n', n_figs, pat.name);

n = 1;
start_fig = gcf;
files = cell(num_events, size(pattern,2));
for i=1:num_events
  for c=1:size(pattern,2)
    fprintf('%d ', n)

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
      h = plot_tfr(data, freq, time, params);
    elseif t_sing && f_sing
      error(['Cannot plot if both time and freqeuncy dimensions are ' ...
             'singleton.'])
    elseif f_sing
      % power vs. time
      data = permute(data, [1 3 4 2]);
      h = plot_erp(data, time, params);
    elseif t_sing
      % power vs. frequency
      data = permute(data, [1 4 2 3]);
      h = plot_freq(data, freq, params);
    end

    % generate the filename
    file_name = sprintf('%s_%s_%s_e%dc%d', pat.name, fig_name, pat.source, i, c);
    files{i,c} = fullfile(res_dir, file_name);

    % print this figure
    print(gcf, params.print_input{:}, files{i,c})
    n = n + 1;
  end
end
fprintf('\n')

% create a new fig object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);
