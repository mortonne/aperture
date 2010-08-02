function pat = pat_erp_image(pat, fig_name, varargin)
%PAT_ERP_IMAGE   Plot an image of all events in a pattern.
%
%  Makes an events X time image for each channel and frequency in a
%  pattern, and also plots the average across events.
%
%  pat = pat_erp_image(pat, fig_name, ...)
%
%  INPUTS:
%       pat:  pattern object.
%
%  fig_name:  string identifier for the new figure object.
%
%  OUTPUTS:
%       pat:  pattern object with an added figure object containing
%             information about the created figures.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_index - defines indices to use when sorting events. May be:
%                     char - indices taken from a field in events.
%                  numeric - vector to use as indices.
%                       [] - indices are 1:length(events). (default)
%   plot_index  - if true, index will be plotted on the image. Default
%                 is true if event_index is specified, otherwise
%                 false.
%   scale_index - if true, index will be scaled before plotting. This is
%                 useful when the index is not ms values. (false)
%   exclude     - use to exclude samples before or after the index
%                 (assuming the index contains ms values). May be:
%                   'before' - only samples after the index are
%                              included in the ERP.
%                    'after' - only samples before the index are included.
%                      'all' - events are excluded if index falls within
%                              exclude_limits.
%                  'inc_all' - events are included only if index falls
%                              within exclude_limits.
%                     'none' - all samples are included. (default)
%   exclude_limits - range of ms values to check for index for
%                 exclusion. If, for a given event, index is outside
%                 this range, all samples will be included. ([])
%   map_limits  - colormap limits in [min max] form. ([])
%   print_input - inputs to print for saving figures. ({'-depsc'})
%   res_dir     - directory in which to save the figure. Default is:
%                  [main_pat_dir]/reports/figs

% options
defaults.event_index = [];
defaults.plot_index = [];
defaults.scale_index = false;
defaults.exclude = 'none';
defaults.exclude_limits = [];
defaults.map_limits = [];
defaults.print_input = {'-depsc'};
defaults.res_dir = '';
params = propval(varargin, defaults);

% set default if user didn't specify whether to plot index
if isempty(params.plot_index)
  if ~isempty(params.event_index)
    params.plot_index = true;
  else
    params.plot_index = false;
  end
end

% prep the output directory
if isempty(params.res_dir)
  report_dir = get_pat_dir(pat, 'reports');
  cd(report_dir)
  params.res_dir = './figs';
end
params.res_dir = check_dir(params.res_dir);

% if iscellstr(channels)
%   match = ismember({pat.dim.chan.label}, channels);
% elseif isnumeric(channels)
%   match = ismember([pat.dim.chan.number], channels);
% elseif isempty(channels)
%   match = true(1, patsize(pat.dim, 'chan'));
% end
% chan_inds = find(match);
% n_chans = length(chan_inds);

% load pattern information
pattern = get_mat(pat);

% prep the event indices
if isempty(params.event_index)
  index = 1:size(pattern, 1);
elseif isnumeric(params.event_index) && isvector(params.event_index)
  % already good to go
  index = params.event_index;
elseif ischar(params.event_index)
  % this is the name of an events field
  events = get_dim(pat.dim, 'ev');
  index = [events.(params.event_index)];
else
  error('invalid event index input.')
end

% dimension info
[n_events, n_chans, n_samps, n_freqs] = size(pattern);
chan = get_dim(pat.dim, 'chan');
freq = get_dim(pat.dim, 'freq');
time = get_dim_vals(pat.dim, 'time');

% remove excluded samples
samplerate = get_pat_samplerate(pat);
start_time = time(1);
mask = true(n_events, n_samps);
if ~strcmp(params.exclude, 'none')
  % NaN out samples before the index on each event
  samp = ms2samp(index, samplerate, start_time);
  
  % get sample limits
  if isempty(params.exclude_limits)
    samp_limits = [1 n_samps];
  else
    samp_limits = ms2samp(params.exclude_limits, samplerate, start_time) + 1;
  end
  
  for i=1:n_events
    if samp(i) < samp_limits(1) || samp_limits(2) < samp(i);
      if strcmp(params.exclude, 'inc_all')
        mask(i, :) = false;
      end
      continue
    end
    switch params.exclude
     case 'before'
      mask(i, 1:samp(i)-1) = false;
     case 'after'
      mask(i, samp(i)+1:end) = false;
     case 'all'
      mask(i, :) = false;
    end
  end
end

% rescale the index (helpful if index is not ms values)
if params.scale_index
  index_min = min(index);
  index_max = max(index);
  time_min = min(time);
  time_max = max(time);
  b = (time_max - time_min) / (index_max - index_min);
  index = b * index + (time_min - b * index_min);
end

z_lim = params.map_limits;
files = cell(1, n_chans, 1, n_freqs);
base_filename = sprintf('%s_%s_%s', pat.name, fig_name, pat.source);
for i=1:n_chans
  for j=1:n_freqs
    clf
    hold on

    % get [events X time] matrix for this channel and freq
    data = squeeze(pattern(:,i,:,j));
    if isempty(params.map_limits)
      absmax = max(abs(data(:)));
      z_lim = [-absmax absmax];
    end

    % plot the events, sorted by index if desired
    subplot('position', [0.175 0.275 0.75 0.65]);
    h = image_sorted(data, time, index, ...
                     'map_limits', z_lim, 'plot_index', params.plot_index);
    xlabel(gca, '');
    set(gca, 'XTickLabel', '');

    % plot the average
    pos = get(gca, 'Position');
    subplot('position', [pos(1) 0.15 pos(3) 0.1]);
    data(~mask) = NaN;
    plot_erp(nanmean(data, 1), time);
    ylabel('V (\muV)')
    drawnow

    % set the filename
    filename = base_filename;
    if n_chans > 1
      filename = [filename '_' lower(strrep(chan(i).label, ' ', '-'))];
    end
    if n_freqs > 1
      filename = [filename '_' lower(strrep(freq(j).label, ' ', '-'))];
    end
    files{1,i,1,j} = fullfile(params.res_dir, [filename '.eps']);
    
    % save
    print(gcf, params.print_input{:}, files{1,i,1,j});
  end
end

% create a new figure object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

