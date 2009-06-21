function files = pat_erp(pat,fig_name,params,res_dir)
%PAT_ERP   Make ERP plots and print them to disk.
%
%  files = pat_erp(pat, fig_name, params, res_dir)
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
%   plot_mult_events - if true, if there are multiple events, they will be
%                      plotted on one axis. Default: true
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
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name','var')
  fig_name = 'erp';
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
if ~exist(res_dir,'dir');
  mkdir(res_dir)
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
  num_events = 1;
else
  num_events = size(pattern,1);
end
files = cell(num_events, size(pattern,2), 1, size(pattern,4));
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);

num_figs = prod(size(files));
fprintf('making %d ERP plots from pattern %s...\n', num_figs, pat.name);
start_fig = gcf;

n = 1;
for i=1:num_events
  for c=1:size(pattern,2)
    for f=1:size(pattern,4)
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
      erp = squeeze(pattern(e,c,:,f));

      if ~isempty(params.stat_name)
        % get significant samples
        p_samp = squeeze(p(e,c,:,f));
        alpha_fw = correct_mult_comp(p_samp, params.alpha, params.correctm);
        params.mark = p_samp < alpha_fw;
      end

      % make the plot
      plot_erp(erp, x, params);

      % generate the filename
      if ndims(pattern)==4
        filename = sprintf('%s_e%dc%df%d.eps', base_filename, i, c, f);
      else
        filename = sprintf('%s_e%dc%d.eps', base_filename, i, c);
      end
      files{i,c,1,f} = fullfile(res_dir, filename);

      % print this figure
      print(gcf, params.print_input, files{i,c,1,f})
      n = n + 1;
    end
  end
end
fprintf('\n')
