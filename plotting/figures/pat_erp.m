function files = pat_erp(pat,fig_name,params,res_dir)
%PAT_ERP   Make ERP plots and print them to disk.
%
%  files = pat_erp(pat, fig_name, params, res_dir)
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
%  OUTPUTS:
%  files:
%
%  PARAMS:
%  print_input:
%  event_bins:
%  mult_fig_windows:

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
end

% set default parameters
params = structDefaults(params, ...
                        'print_input', '-depsc', ...
                        'event_bins', '', ...
                        'mult_fig_windows', 0);

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
start_fig = gcf;
for c=1:size(pattern,2)
  if params.mult_fig_windows
    figure(start_fig + c - 1)
  end
  
  % plot all events for this channel
  h = plot(x, squeeze(pattern(:,c,:)));
  xlabel(x_label)
  ylabel(y_label)
  
  % generate the filename
  file_name = sprintf('%s_%s_%s_c%d', pat.name, fig_name, pat.source, c);
  files{1,c} = fullfile(res_dir, file_name);
  
  % print this figure
  print(gcf, params.print_input, files{1,c})
end
