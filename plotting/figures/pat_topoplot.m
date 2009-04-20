function files = pat_topoplot(pat,fig_name,params,res_dir,relative_dir)
%PAT_TOPOPLOT   Make topoplots and print them to disk.
%
%  files = pat_topoplot(pat,fig_name,params,res_dir,relative_dir)
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
if ~exist('pat','var')
  error('You must pass in a pat object.')
  elseif ~isstruct(pat)
  error('Pat must be a structure.')
  elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~exist('fig_name','var')
  fig_name = 'figure';
end
if ~exist('res_dir','var') | isempty(res_dir)
  if iscell(pat.file)
    pat_file = pat.file{1};
    else
    pat_file = pat.file;
  end
  % save relative to this pattern's main directory
  relative_dir = fileparts(fileparts(pat_file));
  % save relative paths
  res_dir = 'figs';
end
if exist('relative_dir','var')
  % filenames will be relative to this directory
  if ~exist(relative_dir,'dir')
    mkdir(relative_dir)
  end
  if ~exist(fullfile(relative_dir, res_dir), 'dir')
    mkdir(fullfile(res_dir, relative_dir));
  end
  cd(relative_dir)
end
if ~exist(res_dir,'dir')
  mkdir(res_dir);
end
if ~exist('params','var')
  params = struct;
end

% set default parameters
params = structDefaults(params, ...
                        'plot_type',        'topo',                     ...
                        'chan_locs',        '~/eeg/HCGSN128_clean.loc', ...
                        'plot_input',       {},                         ...
                        'map_limits',       [],                         ...
                        'print_input',      {'-depsc'},                 ...
                        'event_bins',       '',                         ...
                        'diff',             false,                      ...
                        'mult_fig_windows', 0,                          ...
                        'stat_name',        '',                         ...
                        'p_range',          [0.005 0.05],               ...
                        'cap_type',         'HCGSN128',                 ...
                        'correctm',         'fdr');

% load the pattern
pattern = load_pattern(pat);

if ~isempty(params.event_bins)
  % create bins using inputs accepted by make_event_bins
  [pat, bins] = patBins(pat, struct('field', params.event_bins));
  % do the averaging within each bin
  pattern = patMeans(pattern, bins);
end

pat_size = patsize(pat.dim);
if ~isempty(params.stat_name)
  % load the p-values
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
  [pattern, map, map_limits] = sig_colormap(p, [max_sig sig], 'two_way_signed');
  colormap(map)

  else
  if params.diff || size(pattern,1)~=1
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

  colormap('default')
end

% set the peripheral channels to the neutral color
to_blank = perimeter_chans(params.cap_type);

fprintf('making topoplots from pattern %s...\n', pat.name)
files = cell(size(pattern,1), 1, size(pattern,3), size(pattern,4));

colorbar
% one plot for each event/time/frequency
for e=1:size(pattern,1)
  for t=1:size(pattern,3)
    for f=1:size(pattern,4)
      % get the slice to plot
      x = squeeze(pattern(e,:,t,f));
      
      % remove perimeter channels
      x(to_blank) = mean(map_limits);
      
      % make the plot
      switch params.plot_type
        case 'topo'
        % make the plot for this slice using the supplied function
        topoplot(x, params.chan_locs, 'maplimits', map_limits, params.plot_input{:});
        
        case 'head'
        
        otherwise
        error('Invalid plot type: %s', params.plot_type)
      end
      
      % write the filename
      filename = sprintf('%s_%s_%s_e%dt%df%d.eps', fig_name, pat.name, pat.source, e,t,f);
      files{e,1,t,f} = fullfile(res_dir, filename);
      
      % print to file
      print(gcf, params.print_input{:}, files{e,1,t,f});
    end
  end
end
