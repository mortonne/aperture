function h = image_sorted(data, index, x, varargin)
%IMAGE_SORTED   Sort and plot a matrix as an image.
%
%  h = image_sorted(data, index, x, varargin)

% input checks
if ~exist('x', 'var')
  x = 1:size(data, 2);
end
y = 1:size(data, 1);

defaults.plot_index = true;
defaults.x_label = 'Time (ms)';
defaults.y_label = 'Trial';
defaults.map_limits = [];
defaults.colormap = [];
defaults.colorbar = true;

params = propval(varargin, defaults);

[index_sorted, ind] = sort(index);

data = data(ind, :);

clf
if ~isempty(params.map_limits)
  h(1) = imagesc(x, y, data, params.map_limits);
else
  h(1) = imagesc(x, y, data);
end

if params.plot_index
  hold on
  step = mean(diff(x)) / 2;
  h(2) = plot(index_sorted + step, y, '-k', 'LineWidth', 3);
end

xlabel(params.x_label)
ylabel(params.y_label)

% colorbar
if params.colorbar
  c = colorbar;
  set(c, 'LineWidth', 2)
end
if ~isempty(params.colormap)
  colormap(params.colormap);
end

% aesthetics
set(gca, 'LineWidth', 2)
if exist('publishfig')==2
  publishfig
end

