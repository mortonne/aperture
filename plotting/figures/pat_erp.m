function files = pat_erp(pat,fig_name,params,res_dir,relative_dir)
%PAT_ERP   Make ERP plots and print them to disk.
%
%  files = pat_erp(pat, fig_name, params, res_dir, relative_dir)
%
%  INPUTS:
%  pat:
%
%  fig_name:
%
%  params:
%
%  res_dir:
%
%  relative_dir:
%
%  OUTPUTS:
%  files:
%
%  PARAMS:
%  print_input:
%  event_bins:
%  mult_fig_windows:
%  colors:
%  y_lim:

if exist('relative_dir','var')
  % filenames will be relative to this directory
  if ~exist(relative_dir,'dir')
    mkdir(relative_dir)
  end
  cd(relative_dir)
end
if ~exist('res_dir','var') | isempty(res_dir)
  % change to this pattern's main directory
  main_dir = fileparts(fileparts(pat.file));
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
                        'y_lim',            []);

% load the pattern
pattern = loadPat(pat);

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

% make one figure per channel
fprintf('Making ERP plots from pattern %s.\nChannel: ', pat.name);
start_fig = gcf;
for c=1:size(pattern,2)
  fprintf('%s ', pat.dim.chan(c).label)
  
  if params.mult_fig_windows
    figure(start_fig + c - 1)
  end
  clf
  
  % plot all events for this channel
  h = plot(x, squeeze(pattern(:,c,:)));
  xlabel(x_label)
  ylabel(y_label)
  
  % use standard y-limits
  if ~isempty(params.y_lim)
    set(gca, 'YLim', params.y_lim)
  end
  
  % change line colors from their defaults
  if ~isempty(params.colors)
    for i=1:length(h)
      set(h(i), 'Color', params.colors{i})
    end
  end
  
  % plot axes
  hold on
  plot(get(gca,'XLim'), [0 0], '--k');
  plot([0 0], get(gca,'YLim'), '--k');
  publishfig
  
  % generate the filename
  file_name = sprintf('%s_%s_%s_c%d', pat.name, fig_name, pat.source, c);
  files{1,c} = fullfile(res_dir, file_name);
  
  % print this figure
  print(gcf, params.print_input, files{1,c})
end
fprintf('\n')
