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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% options
defaults.event_bins = '';
defaults.event_index = [];
defaults.plot_index = [];
defaults.scale_index = false;
defaults.exclude = 'none';
defaults.exclude_limits = [];
defaults.map_limits = [];
defaults.print_input = {'-djpeg10'};
defaults.res_dir = get_pat_dir(pat, 'reports', 'figs');
params = propval(varargin, defaults);

params.res_dir = check_dir(params.res_dir);

% set default if user didn't specify whether to plot index
if isempty(params.plot_index)
  if ~isempty(params.event_index)
    params.plot_index = true;
  else
    params.plot_index = false;
  end
end

% apply event bins
if ~isempty(params.event_bins)
  [binned, bins] = patBins(pat, 'eventbins', params.event_bins);
  bins = bins{1};
  event_labels = get_dim_labels(binned.dim, 'ev');
end

% load the pattern
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
  if iscellstr({events.(params.event_index)})
    index = make_index({events.(params.event_index)});
  else
    index = [events.(params.event_index)];
  end
else
  error('invalid event index input.')
end

% dimension info
[n_events, n_chans, n_samps, n_freqs] = size(pattern);
if exist('bins', 'var')
  n_bins = length(bins);
else
  n_bins = 1;
end
chan_labels = get_dim_labels(pat.dim, 'chan');
freq_labels = get_dim_labels(pat.dim, 'freq');
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
for i = 1:n_bins
  if n_bins > 1
    this_index = index(bins{i});
  else
    this_index = index;
  end
  
  for j = 1:n_chans
    for k = 1:n_freqs
      clf
      hold on

      % get [events X time] matrix for this channel and freq
      if exist('bins', 'var')
        data = squeeze(pattern(bins{i},j,:,k));
      else
        data = squeeze(pattern(:,j,:,k));
      end
      if isempty(params.map_limits)
        % use the absolute 99th percentile instead of the absolute
        % max, so a small number of high or low values doesn't ruin
        % our ability to see the rest of the variability
        abs99 = prctile(abs(data(:)), 99);
        z_lim = [-abs99 abs99];
      end

      % plot the events, sorted by index if desired
      subplot('position', [0.175 0.275 0.75 0.65]);
      h = image_sorted(data, time, this_index, ...
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
      filename = [base_filename '_'];
      if n_bins > 1
        filename = [filename strrep(event_labels{i}, ' ', '-') '_'];
      end
      if n_chans > 1
        filename = [filename strrep(chan_labels{j}, ' ', '-') '_'];
      end
      if n_freqs > 1
        label = strrep(freq_labels{k}, ' ', '-');
        label = strrep(label, '.', '-');
        filename = [filename label '_'];
      end
      if strcmp(filename(end), '_')
        filename = filename(1:end-1);
      end

      if ~isempty(strfind([params.print_input{:}], 'eps'))
        files{i,j,1,k} = fullfile(params.res_dir, [filename '.eps']);
      else
        files{i,j,1,k} = fullfile(params.res_dir, [filename '.jpg']);
      end

      % save
      print(gcf, params.print_input{:}, files{i,j,1,k});
    end
  end
end

% create a new figure object
fig = init_fig(fig_name, files, pat.name);
pat = setobj(pat, 'fig', fig);

