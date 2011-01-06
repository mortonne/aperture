function h = plot_confusion(confmat, class_labels, varargin)
%PLOT_CONFUSION   Plot a confusion matrix from pattern classification.
%
%  h = plot_confusion(confmat, class_labels, ...)
%
%  INPUTS:
%       confmat:  [class X class] confusion matrix. confmat(i,j) gives
%                 the rate at which class i was identified as class j.
%
%  class_labels:  cell array of strings giving the name for each class
%                 in confmat.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   map_limits - [low high] limits for the colormap. ([])

if ~exist('class_labels', 'var')
  class_labels = {};
end

% options
defaults.map_limits = [];
params = propval(varargin, defaults);

n_class = length(confmat);

% plot
clf
if ~isempty(params.map_limits)
  h = imagesc(confmat, params.map_limits);
else
  h = imagesc(confmat);
end
xlabel('Guessed')
ylabel('Right Answer')
axis xy
colorbar

% label the axes
set(gca, 'XTick', 1:n_class)
set(gca, 'YTick', 1:n_class)
if ~isempty(class_labels)
  set(gca, 'XTickLabel', class_labels)
  set(gca, 'YTickLabel', class_labels)
end
publishfig

