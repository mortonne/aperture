function files = plot_class_perf(pat, fig_name, stat_name, params, res_dir)
%PLOT_CLASS_PERF   Make plots of classifier performance.
%
%  files = plot_class_perf(pat, fig_name, stat_name, params, res_dir)
%
%  INPUTS:
%        pat:  a pattern object run through classify_pat.
%
%   fig_name:  string identifier for this set of figures.
%
%  stat_name:  name of the stat object containing classifier performance
%              to plot.
%
%     params:  structure with options for plotting.  See below.
%
%    res_dir:  path to the directory to save figures in. If not 
%              specified, files will be saved in the pattern's
%              reports/figs directory.
%
%  OUTPUTS:
%      files:  cell array of paths to printed figures.
%
%  PARAMS:
%   print_input      - input to print to use when printing figures.
%                      Default: {'-depsc'}

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

params = structDefaults(params, ...
                        'print_input', {'-depsc'});

stat = getobj(pat, 'stat', stat_name);
load(stat.file);

perf = reshape([res.iterations.perf], size(res.iterations));

% average over iterations
perf = nanmean(perf, 1);

% get the non-singleton dimensions
ns = size(perf) > 1;

% set plotting options based on the dimensionality of the data
if ns(3) && ns(4)
  % spectrogram
  x = [pat.dim.time.avg];
  y = [pat.dim.freq.avg];
elseif ns(3)
  % performance vs. time
  x = [pat.dim.time.avg];
  params.y_label = 'Fraction Correct';
elseif ns(4)
  % performance vs. frequency
  x = [pat.dim.freq.avg];
  params.x_label = 'Frequency (Hz)';
  params.y_label = 'Fraction Correct';
  
  % need param to make x-axis log-scale
else
  error(['Both time and frequency dimensions are singleton. Plotting ' ...
         'a single point is not supported.'])
end

for c=1:size(perf,2)
  % get the values for this channel, put in [frequency X time] order
  perfmat = permute(perf(:,c,:,:), [4 3 1 2]);
  
  % plot the performance for this channel
  if isvector(perfmat)
    h = plot_erp(perfmat, x, params);
  else
    h = plot_tfr(perfmat, y, x, params);
  end
  
  % generate a filename
  file_name = sprintf('%s_%s_%s_c%d', pat.name, fig_name, pat.source, c);
  files{1,c} = fullfile(res_dir, file_name);
  
  % print this figure
  print(gcf, params.print_input{:}, files{1,c})
end

