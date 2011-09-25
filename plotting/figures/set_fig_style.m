function set_fig_style(fig, style, varargin)
%SET_FIG_STYLE   Apply a style to a figure.
%
%  set_fig_style(fig, style)
%
%  INPUTS:
%     fig:  handle to a figure (default: gcf)
%
%   style:  string indicating the style to apply. May be:
%            'minimal' (default)
%           Feel free to add your own style as a "case" below!

if nargin < 2
  style = 'minimal';
elseif nargin < 1
  fig = gcf;
end

% assumes only one axis
a = get(fig, 'CurrentAxes');

switch style
 case 'minimal'
  set(a, 'LineWidth', 2)
  box off
  set(a, 'FontSize', 24, 'FontWeight', 'Bold')
  set(get(a, 'XLabel'), 'FontSize', 24, 'FontWeight', 'Bold')
  set(get(a, 'YLabel'), 'FontSize', 24, 'FontWeight', 'Bold')
  
  % set the legend's line width
  l = legend;
  markers = findobj(l, 'LineWidth', 0.5, 'LineStyle', 'none');
  for i = 1:length(markers)
    set(markers(i), 'LineWidth', 3)
  end
end

