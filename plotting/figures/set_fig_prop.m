function set_fig_prop(fig, varargin)
%SET_FIG_PROP   Set properties of a figure.
%
%  Allows setting common properties of a figure using a single
%  structure or using property, value inputs. Also sets figure
%  style in a sensible order; limits/ticks should be set after font
%  size has been determined.
%
%  Lets one set properties without having to remember the relevant
%  graphics handle (gcf, gca, etc.); also lets options easily be
%  passed down through calling functions using propval.
%
%  set_fig_prop(fig, ...)
%
%  INPUTS:
%     fig:  handle to the figure to modify.
%
%  OPTIONS:
%  May be specified using parameter, value pairs or by passing a
%  structure with any of these fields. Defaults shown in parentheses.
%   x_label    - Text label for the x-axis. ('')
%   y_label    - ('')
%   x_lim      - Lower and upper limits for x-axis. ([])
%   y_lim      - ([])
%   x_tick     - Values on x-axis to put ticks and labels. ([])
%   y_tick     - ([])
%   legend_loc - Location of the legend (e.g. 'NorthWest'). ('')
%   fig_style  - see set_fig_style for details. ('minimal')

% options
def.x_label = '';
def.y_label = '';
def.x_lim = [];
def.y_lim = [];
def.x_tick = [];
def.y_tick = [];
def.legend_loc = '';
def.fig_style = 'minimal';
opt = propval(varargin, def);

% assumes only one axis
a = get(fig, 'CurrentAxes');

% axis labels
if ~isempty(opt.x_label)
  xlabel(opt.x_label)
end
if ~isempty(opt.y_label)
  ylabel(opt.y_label)
end

% legend
if ~isempty(opt.legend_loc);
  l = legend;
  set(l, 'Location', opt.legend_loc);
end

% font size, box, etc.
if ~isempty(opt.fig_style)
  set_fig_style(fig, 'minimal')
end

% axis limits
if ~isempty(opt.x_lim)
  set(a, 'XLim', opt.x_lim)
end
if ~isempty(opt.y_lim)
  set(a, 'YLim', opt.y_lim)
end

% axis ticks
if ~isempty(opt.x_tick)
  set(a, 'XTick', opt.x_tick)
end
if ~isempty(opt.y_tick)
  set(a, 'YTick', opt.y_tick)
end

