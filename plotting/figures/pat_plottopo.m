function pat = pat_plottopo(pat, fig_name, varargin)
%PAT_PLOTTOPO   Plot traces on a topo map.
%
%  pat = pat_plottopo(pat, fig_name, ...)
%
%  INPUTS:
%       pat:  pattern object.
%
%  fig_name:  string identifier for the new figure object.
%
%  OUTPUTS:
%       pat:  pattern object with an added figure object containing
%             information about the created figure(s).
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_bins   - input to make_event_bins to average over events
%                  before plotting. ('')
%   event_labels - cell array of strings with labels for each event/
%                  event_bin. ({})
%   chan_locs    - path to a readlocs-compatible electrode locations
%                  file. ('HCGSN128.loc')
%   y_lim        - y-limits to use for each subplot. ([])
%   plot_input   - cell array of additional inputs to plot_topo. ({})
%   res_dir      - directory in which to save the figure(s). Default
%                  is: [main_pat_dir]/reports/figs

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name', 'var')
  fig_name = 'plottopo';
end

% options
defaults.event_bins = '';
defaults.event_labels = {};
defaults.y_lim = [];
defaults.chan_locs = 'HCGSN128.loc';
defaults.stat_name = '';
defaults.plot_input = {};
defaults.res_dir = '';
params = propval(varargin, defaults);

% set y-lim convenience param
time = get_dim_vals(pat.dim, 'time');
x_lim = [min(time) max(time)];
if ~isempty(params.y_lim)
  limits = [x_lim params.y_lim];
else
  limits = [x_lim 0 0];
end
params.plot_input = [params.plot_input {'limits', limits}];

% prep the output directory
if isempty(params.res_dir)
  report_dir = get_pat_dir(pat, 'reports');
  cd(report_dir)
  params.res_dir = './figs';
end
params.res_dir = check_dir(params.res_dir);

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

% cell array to hold paths to printed figures
n_freq = size(pattern, 4);
files = cell(1, 1, 1, n_freq);
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);

% add legend input
if length(params.event_labels) > 1
  params.plot_input = [params.plot_input ...
                      'legend', {params.event_labels}, ...
                      'showleg', 'on'];
end

if n_freq > 1
  fprintf('Making %d plots...', n_freq)
  freq = get_dim(pat.dim, 'freq');
end

eloc = readlocs(params.chan_locs);
for i=1:n_freq
  if n_freq > 1
    fprintf('%s ', freq(i).label)
  end
  
  if ~isempty(params.stat_name)
    % get significant samples
    p_samp = p(:,:,:,i);
    alpha_fw = correct_mult_comp(p_samp(:), params.alpha, params.correctm);
    params.plot_input = [params.plot_input 'mark', p_samp < alpha_fw];
  end
  
  clf
  % get data for this frequency in [channels X time X events] order
  data = permute(pattern(:,:,:,i), [2 3 1 4]);
  plot_topo(data, 'chanlocs', eloc, 'ydir', 1, ...
            params.plot_input{:});
  
  % create the filename for this plot
  if n_freq > 1
    freq_label = lower(strrep(freq(i).label, ' ', '-'));
    filename = sprintf('%s_%s.pdf', base_filename, freq_label);
  else
    filename = sprintf('%s.pdf', base_filename);
  end
  files{1,1,1,i} = fullfile(params.res_dir, filename);
  
  % save as a PDF
  set(gcf, 'PaperOrientation', 'landscape');
  saveas(gcf, files{1,1,1,i});
end
if n_freq > 1
  fprintf('\n')
end

% create a new figure object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

% combine files into one PDF with:
%texexec --paper=landscape --pdfcombine --combination=1*1 \
%        --result out.pdf [files]
