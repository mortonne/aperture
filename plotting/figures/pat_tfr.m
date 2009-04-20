function files = pat_tfr(pat,fig_name,params,res_dir,relative_dir)
%PAT_ERP   Make ERP plots and print them to disk.
%
%  files = pat_erp(pat, fig_name, params, res_dir, relative_dir)
%
%  INPUTS:
%           pat:  a pat object containing the pattern to be plotted.
%
%      fig_name:  string identifier for this set of figures.
%
%        params:  structure with options for plotting. See below.
%
%       res_dir:  path to the directory to save figures in.
%
%  relative_dir:  if specified, the output files cell array will
%                 contain paths that are relative to this directory.
%                 Using relative paths can be useful when later creating
%                 LaTeX reports.
%
%  OUTPUTS:
%         files:  cell array of paths to printed figures.
%
%  PARAMS:
%  Values to plot
%   event_bins       - input to make_event_bins; can be used to average
%                      over events before plotting
%   stat_name        - name of a stat object attached to pat. If
%                      specified, p will be loaded from stat.file, and
%                      significant regions will be shaded below each
%                      ERP plot.
%   alpha            - critical value to use when determining significance.
%                      Default: 0.05
%   correctm         - method to use to correct for multiple comparisions:
%                       [ {none} | fdr | bonferroni ]
%  Plotting options
%   print_input      - input to print to use when printing figures.
%                      Default: '-depsc'
%   fill_color       - color to use for shading under significant time
%                      points. Default: [.8 .8 .8]
%   mult_fig_windows - if true, each figure will be plotted in a separate
%                      window. Default: false
%   colors           - cell array of strings indicating colors to use for
%                      plotting ERPs. colors{i} will be used for plotting
%                      pattern(i,:,:).
%   y_lim            - if specified, y-limit for all figures will be set
%                      to this.

% input checks
if exist('relative_dir','var')
  % filenames will be relative to this directory
  if ~exist(relative_dir,'dir')
    mkdir(relative_dir)
  end
  cd(relative_dir)
end
if ~exist('res_dir','var') | isempty(res_dir)
  if iscell(pat.file)
    pat_file = pat.file{1};
    else
    pat_file = pat.file;
  end
  % change to this pattern's main directory
  main_dir = fileparts(fileparts(pat_file));
  cd(main_dir)
  % save relative paths
  res_dir = 'figs';
end
if ~exist(res_dir,'dir')
  mkdir(res_dir);
end
if ~exist('params','var')
  params = struct;
end
if ~exist('pat','var')
  error('You must pass in a pat object.')
  elseif ~isstruct(pat)
  error('Pat must be a structure.')
  elseif ~isstruct(params)
  error('params must be a structure.')
end

% set default parameters
params = structDefaults(params, ...
                        'map_limits',       [],       ...
                        'print_input',      {'-depsc'}, ...
                        'event_bins',       '',       ...
                        'diff',             false,    ...
                        'mult_fig_windows', 0,        ...
                        'stat_name',        '',       ...
                        'p_range',          [0.005 0.05], ...
                        'correctm',         '');

% load the pattern
pattern = load_pattern(pat);

if ~isempty(params.event_bins)
  % create bins using inputs accepted by make_event_bins
  [pat, bins] = patBins(pat, struct('field', params.event_bins));
  
  % do the averaging within each bin
  pattern = patMeans(pattern, bins);
end

if ~isempty(params.stat_name)
  % get the stat object
  stat = getobj(pat, 'stat', params.stat_name);
  load(stat.file, 'p');

  % HACK - remove any additional p-values
  p = p(1,:,:,:);
  % END HACK
  
  sig = params.p_range(2); % threshold for significance
  max_sig = params.p_range(1); % color gradient will max out here
  
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
  if params.diff || size(pattern,1)~=1
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
x = [pat.dim.time.avg];
y = [pat.dim.freq.avg];

% make one figure per channel
fprintf('making TFR plots from pattern %s...\nchannel: ', pat.name);
start_fig = gcf;
files = cell(1, size(pattern,2));
for c=1:size(pattern,2)
  fprintf('%s ', pat.dim.chan(c).label)
  
  if params.mult_fig_windows
    figure(start_fig + c - 1)
  end
  clf

  % get the channel to plot and reorder dimensions for plot_tfr
  spec = permute(nanmean(pattern(:,c,:,:),1), [4 3 1 2]);
  
  % make the spectrogram
  h = plot_tfr(spec, y, x, params);

  % generate the filename
  file_name = sprintf('%s_%s_%s_c%d', pat.name, fig_name, pat.source, c);
  files{1,c} = fullfile(res_dir, file_name);
  
  % print this figure
  print(gcf, params.print_input{:}, files{1,c})
end
fprintf('\n')