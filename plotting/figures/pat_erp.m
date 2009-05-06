function files = pat_erp(pat,fig_name,params,res_dir,relative_dir)
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
  res_dir = './figs';
end
if ~strcmp(res_dir(1),'/')
  res_dir = ['./' res_dir];
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
end

% set default parameters
params = structDefaults(params, ...
                        'print_input',      '-depsc', ...
                        'event_bins',       '',       ...
                        'plot_mult_events', true,     ...
                        'mult_fig_windows', 0,        ...
                        'colors',           {},       ...
                        'y_lim',            [],       ...
                        'stat_name',        '',       ...
                        'alpha',            0.05,     ...
                        'correctm',         '',       ...
                        'fill_color',       [.8 .8 .8]);

% load the pattern
pattern = load_pattern(pat);

if ~isempty(params.event_bins)
  % create bins using inputs accepted by make_event_bins
  [pat, bins] = patBins(pat, struct('field', params.event_bins));
  
  % do the averaging within each bin
  pattern = patMeans(pattern, bins);
end

% make sure this is a voltage pattern
if ndims(pattern)>3
  error('pattern cannot have a frequency (4th) dimension.')
end

% set axis information
x = [pat.dim.time.avg]; % for each time bin, use the mean value

if ~isempty(params.stat_name)
  % get the stat object
  stat = getobj(pat, 'stat', params.stat_name);
  load(stat.file, 'p');

  % HACK - remove any additional p-values and take absolute value
  p = abs(p(1,:,:,:));
  % END HACK
  
  % check the size
  pat_size = patsize(pat.dim);
  stat_size = size(p);
  if any(pat_size(2:3)~=stat_size(2:3))
    error('p must be the same size as pattern.')
  end
end

% initialize a cell array to hold all the printed figures
if params.plot_mult_events
  files = cell(1, size(pattern,2));
  num_events = 1;
else
  files = cell(size(pattern,1), size(pattern,2));
  num_events = size(pattern,1);
end

num_figs = prod(size(files));
fprintf('making %d ERP plots from pattern %s...\n', num_figs, pat.name);
start_fig = gcf;

n = 1;
for i=1:num_events
  for c=1:size(pattern,2)
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
    erp = squeeze(pattern(e,c,:));

    if ~isempty(params.stat_name)
      % get significant samples
      params.mark = correct_mult_comp(squeeze(p(e,c,:)), params.alpha, params.correctm);
    end

    % make the plot
    plot_erp(erp, x, params);

    % generate the filename
    file_name = sprintf('%s_%s_%s_e%dc%d.eps', ...
    pat.name, fig_name, pat.source, i, c);
    files{i,c} = fullfile(res_dir, file_name);

    % print this figure
    print(gcf, params.print_input, files{i,c})
    n = n + 1;
  end
end
fprintf('\n')
