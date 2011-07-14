function h = plot_targets(targets, x, y, varargin)
%PLOT_TARGETS   Plot classification targets.
%
%  h = plot_targets(targets, x, y, ...)
%
%  PARAMS:
%   colors - ({'r' 'b' 'g'})

% options
defaults.colors = {'r' 'b' 'g'};
params = propval(varargin, defaults);

[n_cond, n_events] = size(targets);
if ~exist('x', 'var')
  x = 1:n_events;
end
if ~exist('y', 'var')
  y = 1:n_cond;
end

% flip vertically to match the order in the matrix
targets = flipud(targets);
params.colors = fliplr(params.colors);

hold on
for i = 1:n_cond
  these_targets = double(targets(i,:));
  these_targets(these_targets == 0) = NaN;
  these_targets(these_targets == 1) = y(i);
  h(i) = plot(x, these_targets, params.colors{i}, ...
              'LineWidth', 2, 'LineStyle', '-', 'Marker', 'o', ...
              'MarkerFaceColor', params.colors{i});
end
hold off

