function [map, crit] = thresh_colormap(limits, thresh, map_size, colors)
%THRESH_COLORMAP   Create a thresholded colormap.
%
%  Creates a colormap around zero. If -thresh < limits(1), the map
%  will be one-sided positive; if thresh > limits(2), the map will
%  be one-sided negative; otherwise, it will be two-sided.
%
%  map = thresh_colormap(limits, thresh, map_size, colors)
%
%  INPUTS:
%    limits:  lower and upper limit values.
%
%    thresh:  threshold indicating parts of the map to have color.
%
%  map_size:  resolution of the color map.
%
%    colors:  colors to use for different parts of the map. Default is
%             to use red for positive, blue for negative, with values
%             below threshold set to white.
%
%  OUTPUTS:
%      map:  [map_size X 3] matrix of RGB values.

if nargin < 4
  colors = [0 0 1
            .8 .8 1
            1 1 1
            1 .8 .8
            1 0 0];
end

map = nan(map_size, 3);
if -thresh < limits(1) && thresh > limits(2)
  error('Threshold out of bounds.')
elseif -thresh < limits(1)
  % one-sided positive
  points = [limits(1) thresh
            thresh limits(2)];
  point_colors = {[colors(3,:); colors(3,:)] ...
                  [colors(4,:); colors(5,:)]};
  crit = [limits(1) thresh limits(2)];
elseif thresh > limits(2)
  % one-sided negative
  points = [limits(1) -thresh
            -thresh limits(2)];
  point_colors = {[colors(1,:); colors(2,:)] ...
                  [colors(3,:); colors(3,:)]};
  crit = [limits(1) -thresh limits(2)];
else
  % two-sided
  points = [limits(1) -thresh
            -thresh thresh
            thresh limits(2)];
  point_colors = {[colors(1,:); colors(2,:)] ...
                  [colors(3,:); colors(3,:)] ...
                  [colors(4,:); colors(5,:)]};
  crit = [limits(1) -thresh thresh limits(2)];
end

for i = 1:size(points, 1)
  m_start = val2color(points(i,1), limits, map_size);
  m_finish = val2color(points(i,2), limits, map_size);
  
  if i == size(points, 1)
    grad_size = m_finish - m_start + 1;
    ind = m_start:m_finish;
  else
    grad_size = m_finish - m_start;
    ind = m_start:(m_finish - 1);
  end
  window = gradient(point_colors{i}(1,:), point_colors{i}(2,:), grad_size);
  map(ind,:) = window;
end
if any(isnan(map))
  error('Unfilled map entries.')
end


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
  color_index = 1 + round(x * (map_size - 1));
            
function map = gradient(startcol, endcol, n_points)

  map = NaN(n_points, 3);
  for i = 1:3
    map(:,i) = linspace(startcol(i), endcol(i), n_points);
  end

