function h = image_sorted(data, x, index, varargin)
%IMAGE_SORTED   Sort and plot a matrix as an image.
%
%  h = image_sorted(data, x, index, ...)
%
%  INPUTS:
%     data:  numeric array containing values to be plotted.
%
%        x:  values for the x-axis.
%
%    index:  vector of indices for sorting the rows of data before
%            plotting.
%
%  OUTPUTS:
%        h:  handle to the image graphics.
%
%  PARAMS:
%  May be specified using a structure or parameter, value pairs.
%  Defaults are shown in parentheses.
%   plot_index - logical specifying whether to plot the index on top of
%                the image. (true)
%   x_label    - string label for the x-axis. ('Time (ms)')
%   y_label    - string label for the y-axis. ('Trial')
%   map_limits - limits for the colormap. ([])
%   colormap   - colormap to use for plotting images. ([])
%   colorbar   - logical; if true, a colorbar will be shown. (true)

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

% input checks
if nargin < 2 || isempty(x)
  x = 1:size(data, 2);
end
if nargin < 3 || isempty(index)
  index = 1:size(data, 1);
  defaults.plot_index = false;
else
  defaults.plot_index = true;  
end
y = 1:size(data, 1);

% options
defaults.x_label = 'Time (ms)';
defaults.y_label = 'Trial';
defaults.map_limits = [];
defaults.colormap = [];
defaults.colorbar = true;
defaults.plot_ind_bounds = false;
params = propval(varargin, defaults);

[index_sorted, ind] = sort(index);

data = data(ind, :);

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

if params.plot_ind_bounds
  hold on
  bounds = find(diff(index_sorted));
  for i=1:length(bounds)
    line([min(x) max(x)],[bounds(i) bounds(i)], ...
         'LineWidth', 3, 'Color', 'k');
  end
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
axis xy

