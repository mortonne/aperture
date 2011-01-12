function [z, map, map_limits] = sig_colormap(p, alpha_range, map_size, dir)
%SIG_COLORMAP   Create a colormap for plotting significance.
%
%  Create a colormap that colors only significant values, and plots
%  all other values as white.
%
%  IMPORTANT: You must set the map limits of your plot to map_limits,
%  or the map will not be valid.
%
%  [z, map, map_limits] = sig_colormap(p, alpha_range, map_size, dir)
%
%  INPUTS:
%            p:  array of p-values to be plotted.
%
%  alpha_range:  range of p-values to color. alpha_range(1) is the
%                significance threshold; if abs(p) < alpha_range(1) it
%                will be colored. alpha_range(2) corresponds to the
%                darkest color. Default: [0.05 0.005]
%
%     map_size:  size of the colormap. Higher values give higher
%                resolution, and more accurate mapping of p-value to
%                color. Default: 512
%
%          dir:  array of 1 and -1 giving the direction of the effect
%                for each p-value. If not specified, all will be plotted
%                as negative (blue).
%
%  OUTPUTS:
%            z:  input p-values transformed to correspond to the color
%                map. Same as norminv(p).
%
%          map:  colormap with the desired color regions. You can make
%                it your current color map with colormap(map). To view,
%                use colormapeditor.
%
%   map_limits:  z-scores corresponding to the edges of the map.

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
if ~exist('p', 'var') || ~isnumeric(p)
  error('You must supply an array of p-values.')
end
if ~exist('alpha_range', 'var')
  alpha_range = [0.05 0.005];
elseif ~isnumeric(alpha_range) || diff(alpha_range) > 0
  error('alpha_range must be an increasing numeric array.')
end
if ~exist('dir', 'var')
  dir = repmat(-1, size(p));
  unsigned = true;
end
if ~exist('map_size', 'var')
  map_size = 512;
end
if any(p < 0)
  error('p-values cannot be negative.')
end

% RGB values for the colors we will use
WHITE = [1 1 1];
LT_BLUE = [.8 .8 1];
DK_BLUE = [0 0 1];
LT_RED = [1 .8 .8];
DK_RED = [1 0 0];

% get corresponding z-values
z = NaN(size(p));
z(dir == 1) = norminv(1 - p(dir == 1));
z(dir == -1) = norminv(p(dir == -1));

% if either of our alphas are 0, make it eps
% so norminv will be defined
alpha_range(alpha_range == 0) = eps(0);

if unsigned
  % treat the p-values as negative
  z_neg = norminv(alpha_range(1));
  z_neg_max = norminv(alpha_range(2));
  
  % define the colormap
  windows{1} = [z_neg_max z_neg];
  window_colors = { {DK_BLUE LT_BLUE} };
  [map, map_limits] = make_sig_map(windows, window_colors, ...
                                   [z_neg_max 0], map_size);
else
  error('plotting with direction currently not supported.')
  
  % get all the points of inflection for the map
  neg_sig = norminv(alpha_range(1));
  neg_max_sig = norminv(alpha_range(2));
  pos_sig = norminv(1 - alpha_range(1));
  pos_max_sig = norminv(1 - alpha_range(2));

  % write values for each area of the map
  windows{1} = [neg_max_sig  neg_sig    ];
  windows{2} = [pos_sig      pos_max_sig];

  % set the corresponding colors
  window_colors = { { DK_BLUE, LT_BLUE}, ...
                    { LT_RED,  DK_RED } };

  % make the colormap
  [map, map_limits] = make_sig_map(windows, window_colors, [], map_size);
end

z(z < map_limits(1)) = map_limits(1);
z(z > map_limits(2)) = map_limits(2);


function [map, map_limits] = make_sig_map(windows, window_colors, ...
                                          val_range, map_size)
  %MAKE_SIG_MAP   Make a colormap to use for plotting significance.
  %
  %  [map, map_limits] = make_sig_map(windows, window_colors,
  %                                   val_range, map_size)
  %
  %  INPUTS:
  %        windows:  cell array of 1X2 vectors, where windows{i}(1)
  %                  gives the starting value of window i, and
  %                  windows{i}(2) gives the end value of window i.
  %
  %  window_colors:  cell array of colors (in RGB format) corresponding
  %                  to each window. Each cell can either contain a
  %                  single color or a 1X2 cell array of colors,
  %                  indicating start and end colors for a gradient.
  %
  %      val_range:  range of values that will correspond to the full
  %                  color map. Default is
  %                  [windows{1}(1) windows{end}(2)].
  %
  %       map_size:  integer indicating the size of the color map. Use
  %                  larger values for higher resolution. Default: 128.
  %
  %  OUTPUTS:
  %            map:  a color map. Areas that were not specified in the
  %                  windows but are within val_range are colored white.
  %
  %     map_limits:  limits of the color map.

  % input checks
  if ~exist('windows', 'var')
    error('You must specify values to map the colors onto.')
  elseif ~exist('window_colors', 'var')
    error('You must specify colors for the endpoints of each window.')
  end
  if ~exist('val_range', 'var') || isempty(val_range)
    % use the first value in the first window
    % to the last value in the last window
    val_range = [windows{1}(1) windows{end}(2)];
  end
  if ~exist('map_size', 'var')
    map_size = 128;
  end

  % initialize as a white map
  map = ones(map_size,3);
  for i=1:length(windows)
    % sanity checks
    if diff(windows{i}) < 0
      error('window %d is not increasing.', i)
    elseif windows{i}(1) < val_range(1) || windows{i}(2) > val_range(2)
      error('window %d falls outside of val_range.', i)
    end

    % get the map indices for this window
    map_start = val2color(windows{i}(1), val_range, map_size);
    map_end = val2color(windows{i}(2), val_range, map_size);
    map_window = map_start:map_end;

    if isnumeric(window_colors{i})
      % if only one color, expand to start and end colors
      window_colors{i} = repmat(window_colors(i),1,2);
    end

    % create the map for this window
    map(map_window,:) = makecolormap(window_colors{i}{:}, length(map_window));
  end
  
  map_limits = val_range;


function color_index = val2color(val, val_range, map_size)
  %VAL2COLOR   Get the index in a colormap for a given value.
  %
  %  color_coord = val2color(val, val_range, map_size)
  %
  %  INPUTS:
  %          val:  scalar indicating a value.
  %  
  %    val_range:  range of values corresponding to the color
  %                map
  %
  %     map_size:  size of the color map.
  %
  %  OUTPUTS:
  %  color_index:  index of val in the color map.
  
  % get the proportional value of val
  x = (val - val_range(1)) / diff(val_range);
  
  % translate to color space
  if x == 0
    color_index = 1;
  else
    color_index = ceil(x * map_size);
  end

