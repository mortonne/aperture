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
%       print_input:
%        event_bins:
%  mult_fig_windows:
%            colors:
%             y_lim:
%         stat_name:
%             alpha:
%          correctm:  ('', 'fdr', 'bonferroni')
%        fill_color:

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
                        'print_input',      '-depsc', ...
                        'event_bins',       '',       ...
                        'mult_fig_windows', 0,        ...
                        'colors',           {},       ...
                        'y_lim',            [],       ...
                        'stat_name',        '',       ...
                        'alpha',            0.05,     ...
                        'correctm',         '',       ...
                        'fill_color',       [.8 .8 .8]);

% load the pattern
pattern = load_pattern(pat);
if isempty(pattern)
  error('pattern %s is empty.', pat.name)
end

if ~isempty(params.event_bins)
  % create bins using inputs accepted by binEventsField
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
x_label = 'Time (ms)';
y_label = 'Voltage (uV)';

if ~isempty(params.stat_name)
  % get the stat object
  stat = getobj(pat, 'stat', params.stat_name);
  if isempty(stat)
    error('pat %s does not contain a stat object named %s.', pat.name, params.stat_name)
  end
  
  % load the p-values
  load(stat.file);
  if ~exist('p','var')
    error('stat file must contain a variable named "p".')
  end
  
  % check the size
  pat_size = patsize(pat.dim);
  stat_size = size(p);
  if any(pat_size(2:3)~=stat_size(2:3))
    error('p must be the same size as pattern.')
  end
end

% make one figure per channel
fprintf('Making ERP plots from pattern %s.\nChannel: ', pat.name);
start_fig = gcf;
files = cell(1, size(pattern,2));
for c=1:size(pattern,2)
  fprintf('%s ', pat.dim.chan(c).label)
  
  if params.mult_fig_windows
    figure(start_fig + c - 1)
  end
  clf

  % event-related potential(s) for this channel
  erp = squeeze(pattern(:,c,:));
  
  % min and max of the data
  y_min = min(erp(:));
  y_max = max(erp(:));

  % set the y-limits
  if ~isempty(params.y_lim)
    % use standard y-limits
    y_lim = params.y_lim;
    else
    % buffer from top and bottom
    buffer = (y_max-y_min)*0.2;
    y_lim = [y_min-buffer y_max+buffer];
  end
  
  % shade significant regions
  if ~isempty(params.stat_name)
    % get significant samples
    sig = correct_mult_comp(squeeze(p(:,c,:)), params.alpha, params.correctm);

    % shade significant samples
    offset = diff(y_lim)*0.07;
    bar_y = min(erp(:)) - offset;
    bar_y_lim = [(bar_y - offset/2) bar_y];
    shade_regions(x, sig, bar_y_lim, params.fill_color);
    hold on
  end
  
  % plot all events for this channel
  h = plot(x, erp);
  xlabel(x_label)
  ylabel(y_label)
 
  % change line colors from their defaults
  if ~isempty(params.colors)
    for i=1:length(h)
      set(h(i), 'Color', params.colors{i})
    end
  end

  % set y-limits
  set(gca, 'YLimMode','manual')
  set(gca,'YLim',y_lim)
  
  % plot axes
  hold on
  plot(get(gca,'XLim'), [0 0], '--k');
  plot([0 0], y_lim, '--k');
  publishfig

  % generate the filename
  file_name = sprintf('%s_%s_%s_c%d', pat.name, fig_name, pat.source, c);
  files{1,c} = fullfile(res_dir, file_name);
  
  % print this figure
  print(gcf, params.print_input, files{1,c})
end
fprintf('\n')


function shade_regions(x,sig,y_lim,fill_color)
  %SHADE_REGIONS   Shade in multiple rectangles.
  %
  %  shade_regions(x,sig,y_lim,fill_color)
  %
  %  INPUTS:
  %           x:  vector of x values.
  %
  %         sig:  boolean vector where indices to shade are true.
  %               Must correspond to x.
  %
  %       y_lim:  two-element array of the form [y_min y_max],
  %               indicating the y-limits of each shaded region.
  %
  %  fill_color:  color to use when shading each region.
  
  % pad x so we can count start and end right
  diff_vec = diff([0 sig(:)' 0]);

  % get the start and end of each region
  starts = find(diff_vec(1:end-1)==1);
  ends = find(diff_vec(2:end)==-1);

  nRegions = length(starts);
  for i=1:nRegions
    % start end end start
    l2r = [starts(i) ends(i)];
    r2l = fliplr(l2r);

    % x and y coords of this polygon
    region_x = [x(l2r) x(r2l)];
    region_y = [y_lim(1) y_lim(1) y_lim(2) y_lim(2)];

    % fill the region
    h = fill(region_x, region_y, fill_color);
    set(h, 'edgecolor', fill_color)
    hold on
  end
%endfunction
