function pat = pat_erp_image(pat, channels, varargin)
%PAT_ERP_IMAGE   Plot an image of all events in a pattern.
%
%  pat = pat_erp_image(pat)
%
%  NOTES:
%   Currently doesn't save out any figures, and isn't well suited for
%   patterns with multiple channels.

defaults.map_limits = [];
params = propval(varargin, defaults);

pattern = get_mat(pat);
time = get_dim_vals(pat.dim, 'time');

if iscellstr(channels)
  match = ismember({pat.dim.chan.label}, channels);
elseif isnumeric(channels)
  match = ismember([pat.dim.chan.number], channels);
elseif isempty(channels)
  match = true(1, patsize(pat.dim, 'chan'));
end
chan_inds = find(match);
n_chans = length(chan_inds);

z_lim = params.map_limits;
for i=chan_inds
  clf
  hold on

  data = squeeze(pattern(:,i,:,:));
  if ndims(data) > 2
    error('each channel must only have two dimensions.')
  end
  
  if isempty(params.map_limits)
    absmax = max(abs(data(:)));
    z_lim = [-absmax absmax];
  end
  
  subplot('position', [0.175 0.275 0.75 0.65]);
  h = image_sorted(data, time, 1:size(data,1), ...
                   'map_limits', z_lim, 'plot_index', false);
  xlabel(gca, '');
  set(gca, 'XTickLabel', '');
  
  pos = get(gca, 'Position');
  subplot('position', [pos(1) 0.15 pos(3) 0.1]);
  plot_erp(squeeze(nanmean(pattern(:,i,:,:), 1)), time);
  ylabel('V (\muV)')
  drawnow
end


