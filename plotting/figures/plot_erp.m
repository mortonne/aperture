function h = plot_erp(data, time, varargin)
%PLOT_ERP   Plot an event-related potential.
%
%  h = plot_erp(data, time, ...)
%
%  INPUTS:
%     data:  array of voltage values to plot. If data is a matrix, each
%            row will be plotted as a separate line.
%
%     time:  time values corresponding to each column of data.
%
%  OUTPUTS:
%        h:  vector of handles for each line plotted.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   x_lim      - limits of the time axis in [min, max] form. ([])
%   time_units - units of the time axis. ('ms')
%   x_label    - label for the x-axis. ('Time (time_units)' if time
%                vector given, otherwise 'Time (samples)')
%   y_lim      - limits of the voltage axis in [min, max] form. ([])
%   volt_units - units of the voltage axis. ('\muV')
%   y_label    - label for the y-axis. ('Voltage (volt_units)')
%   plot_input - cell array of additional inputs to plot. ({})
%   colors     - cell array indicating the order of colors to use for
%                the lines. ({})
%   mark       - boolean vector indicating samples to be marked
%                (e.g., significant samples). Shading will be put just
%                below the plot. ([])
%   fill_color - [1 X 3] array giving the color to use for marks.
%                ([.8 .8 .8])
%   labels     - cell array of labels for lines in legend. ({})
%   legend_input - cell array of additional inputs to legend. ({})
%
%  See also pat_erp.

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
if ~exist('data', 'var')
  error('You must pass a matrix of values to plot.')
end
if ~exist('time', 'var')
  time = [];
end

% set default parameters
def.time_units = 'ms';
def.volt_units = '\muV';
def.colors = {};
def.plot_input = {'LineWidth', 3};
def.mark = [];
def.fill_color = [.8 .8 .8];
def.labels = {};
def.legend_input = {};
def.plot_zero = true;
[opt, plot_opt] = propval(varargin, def);

def = [];
def.x_lim = [];
def.y_lim = [];
def.x_label = '';
def.y_label = '';
plot_opt = propval(plot_opt, def, 'strict', false);

%% x-axis

% time values
if ~isempty(time)
  x = time;
else
  x = 1:size(data, 2);
end

% label
if isempty(plot_opt.x_label)
  if ~isempty(time)
    plot_opt.x_label = sprintf('Time (%s)', opt.time_units);
  else
    plot_opt.x_label = 'Time (samples)';
  end
end

% limits
if isempty(plot_opt.x_lim)
  plot_opt.x_lim = [x(1) x(end)];
end

%% y-axis

% label
if isempty(plot_opt.y_label)
  plot_opt.y_label = sprintf('Voltage (%s)', opt.volt_units);
end

% min and max of the data
y_min = min(data(:));
if isnan(y_min)
  y_min = -1;
end
y_max = max(data(:));
if isnan(y_max)
  y_max = 1;
end

% limits
if isempty(plot_opt.y_lim)
  % buffer from top and bottom
  buffer = (y_max - y_min) * 0.2;
  plot_opt.y_lim = [y_min - buffer y_max + buffer];
end

% mark samples
hold on
if ~isempty(opt.mark)
  if ~isvector(opt.mark)
    error('opt.mark must be a vector.')
  elseif length(opt.mark) ~= length(x)
    error('opt.mark must be the same length as data.')
  end
  
  offset = diff(plot_opt.y_lim) * 0.07;
  bar_y = y_min - offset;
  bar_y_lim = [(bar_y - offset / 2) bar_y];
  shade_regions(x, opt.mark, bar_y_lim, opt.fill_color);
end

% make the plot
h = plot(x, double(data), '-k', opt.plot_input{:});

% change line colors from their defaults
if ~isempty(opt.colors)
  for i = 1:length(h)
    set(h(i), 'Color', opt.colors{mod(i - 1, length(opt.colors)) + 1})
  end
end

% add legend and line labels
if ~isempty(opt.labels)
  l = legend(h, opt.labels, opt.legend_input{:});
end

% set figure properties, style
set_fig_prop(gcf, plot_opt);

% plot axes
if opt.plot_zero
  x_lim = get(gca, 'XLim');
  y_lim = get(gca, 'YLim');
  plot(x_lim, [0 0], '--k', 'LineWidth', 3);
  if x_lim(1) < 0
    plot([0 0], y_lim, '--k', 'LineWidth', 3);
  end
end

% remove the legend if there aren't any labels
if isempty(opt.labels)
  axhand = gca;
  leghand = get(axhand,'Legend');
  set(leghand,'Visible','off');
end

hold off
keyboard

function shade_regions(x, mark, y_lim, fill_color)
  %SHADE_REGIONS   Shade in multiple rectangles.
  %
  %  shade_regions(x, mark, y_lim, fill_color)
  %
  %  INPUTS:
  %           x:  vector of x values.
  %
  %        mark:  boolean vector where indices to shade are true.
  %               Must correspond to x.
  %
  %       y_lim:  two-element array of the form [y_min y_max],
  %               indicating the y-limits of each shaded region.
  %
  %  fill_color:  color to use when shading each region.
  
  % pad x so we can count start and end right
  diff_vec = diff([0 mark(:)' 0]);

  % get the start and end of each region
  starts = find(diff_vec(1:end-1)==1);
  ends = find(diff_vec(2:end)==-1);

  nRegions = length(starts);
  for i=1:nRegions
    % start end end start
    l2r = [starts(i) ends(i)];
    r2l = fliplr(l2r);

    % x and y coords of this polygon
    region_x = [x(l2r) x(r2l)];
    region_y = [y_lim(1) y_lim(1) y_lim(2) y_lim(2)];

    % fill the region
    h = fill(region_x, region_y, fill_color);
    set(h, 'edgecolor', fill_color)
    hold on
  end

