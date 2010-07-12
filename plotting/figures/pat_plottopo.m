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
%      pat:  pattern object with an added figure object containing
%            information about the created figure(s).
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_bins
%   chan_locs
%   y_lim
%   plot_input
%   res_dir
%   print_input

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass in a pat object.')
end
if ~exist('fig_name', 'var')
  fig_name = 'plottopo';
end

% options
defaults.event_bins = '';
defaults.y_lim = [];
defaults.chan_locs = '~/eeg/HCGSN128.loc';
defaults.plot_input = {};
defaults.res_dir = '';
defaults.print_input = {'-depsc'};
params = propval(varargin, defaults);

% set y-lim convenience param
if ~isempty(params.y_lim)
  params.plot_input = [params.plot_input {'ylim', params.y_lim}];
end

% prep the output directory
if isempty(params.res_dir)
  report_dir = get_pat_dir(pat, 'reports');
  cd(report_dir)
  params.res_dir = './figs';
end
params.res_dir = check_dir(params.res_dir);

if ~isempty(params.event_bins)
  % apply binning (don't modify the pat object, even in the workspace)
  pattern = get_mat(bin_pattern(pat, ...
                                'eventbins', params.event_bins, ...
                                'save_mats', false));
else
  % just get the pattern
  pattern = get_mat(pat);
end

% cell array to hold paths to printed figures
n_freq = size(pattern, 4);
files = cell(1, 1, 1, n_freq);
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);

eloc = readlocs(params.chan_locs);
for i=1:n_freq
  clf
  
  % get data for this frequency in [channels X time X events] order
  data = permute(pattern(:,:,:,i), [2 3 1 4]);
  plottopo(data, 'chanlocs', eloc, 'ydir', 1, ...
           params.plot_input{:});
  
  % create the filename for this plot
  if n_freq > 1
    filename = sprintf('%s_f%d.pdf', base_filename);
  else
    filename = sprintf('%s.pdf', base_filename);
  end
  files{1,1,1,i} = fullfile(params.res_dir, filename);
  
  % save as a PDF
  set(gcf, 'PaperOrientation', 'landscape');
  saveas(gcf, files{1,1,1,i});
end

% create a new figure object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

% combine files into one PDF with:
%texexec --paper=landscape --pdfcombine --combination=1*1 \
%        --result out.pdf [files]