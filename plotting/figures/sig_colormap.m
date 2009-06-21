function [z,map,map_limits] = sig_colormap(p,p_range,p_type,map_size)
%SIG_COLORMAP   Create a colormap for plotting significant t-statistics.
%
%  [z, map] = sig_colormap(p, p_range, p_type)
%
%  Create a colormap that colors only significant values, and plots
%  all other values as white.
%
%  The complication here is that p-values vary depending on whether
%  the test was one-way or two-way. 
%
%  For two-way tests, we want:
%   0 to alpha    blue
%   1-alpha to 1  red
%
%  For one-way tests, we will use blue to indicate unsigned significance:
%   0 to alpha    blue
%
%  p-values from one-way tests can have the direction indicated by
%  the color if they are signed, that is, if the input p-values are
%  negative for significant negative differences between conditions.
%  For signed one-way tests, we want:
%   -alpha to 0   blue
%   0 to alpha    red
%
%  IMPORTANT: You must set the map limits of your plot to map_limits,
%  or the map will not be valid.
%
%  INPUTS:
%         p:  array of p-values to be plotted.
%
%   p_range:  range of p-values to color. p_range(1) is the lowest
%             p-value to begin the gradient; all p-values below that
%             will have the same color. p_range(2) gives the highest
%             p-value the color.
%
%    p_type:  type of p-value passed in. Can be:
%              one_way           - significant p-values are 0 to alpha
%                                  and (1-alpha) to 1.
%              two_way (default) - significant p-values are 0 to alpha.
%                                  p has no information about the direction
%                                  of effect.
%              two_way_signed    - same as two_way, but the sign of the
%                                  p-value indicates the direction
%                                  of the effect.
%              
%  map_size:  size of the colormap (default: 512). Higher values
%             give higher resolution, and more accurate mapping of
%             p-value to color.
%
%  OUTPUTS:
%         z:  input p-values transformed to correspond to the color
%             map. Same as norminv(p).
%
%       map:  colormap with the desired color regions. You can make
%             it your current color map with colormap(map). To view, use
%             colormapeditor.

% input checks
if ~exist('p','var') || ~isnumeric(p)
  error('You must supply an array of p-values.')
end
if ~exist('p_range','var')
  p_range = [0.005 0.05];
  elseif ~isnumeric(p_range) || diff(p_range)<0
  error('p_range must be an increasing numeric array.')
end
if ~exist('p_type','var')
  p_type = 'two_way';
end
if ~exist('map_size','var')
  map_size = 512;
end

% RGB values for the colors we will use
WHITE = [1 1 1];
LT_BLUE = [.8 .8 1];
DK_BLUE = [0 0 1];
LT_RED = [1 .8 .8];
DK_RED = [1 0 0];

switch p_type
  case 'one_way'
  % 0 to alpha    1-alpha to 1
  % blue          red
  error('one-way p-values currently not supported.')
  
  case 'two_way'
  % 0 to alpha
  % red
  
  % if either of our alphas are 0, make it eps
  % so norminv will be defined
  p_range(p_range==0) = eps;
  
  % points of inflection for the map
  sig = norminv(p_range(2));
  max_sig = norminv(p_range(1));
  
  % write values for each area 
  windows{1} = [max_sig sig];
  windows{2} = [sig -max_sig];
  
  % set the corresponding colors
  window_colors = { { DK_RED, LT_RED }, ...
                      WHITE            };

  % make the colormap
  [map, map_limits] = make_sig_map(windows, window_colors, [], map_size);
  z = norminv(p);
  
  case 'two_way_signed'
  % -alpha to 0   0 to alpha
  % blue          red
  
  % set p-values above 0.5 to 0.5
  trim = abs(p)>.5;
  p(trim) = .5*sign(p(trim));
  
  % flip the positive values around
  pos = p>0;
  p(pos) = 1-p(pos);
  
  % reflect the negative values over the y-axis
  p = abs(p);
  
  % transform to z-space
  z = norminv(p);
  
  % if either of our alphas are 0, make it eps
  % so norminv will be defined
  p_range(p_range==0) = eps;
  
  % get all the points of inflection for the map
  neg_sig = norminv(p_range(2));
  neg_max_sig = norminv(p_range(1));
  pos_sig = norminv(1-p_range(2));
  pos_max_sig = norminv(1-p_range(1));
  
  % write values for each area of the map
  windows{1} = [neg_max_sig  neg_sig    ];
  windows{2} = [pos_sig      pos_max_sig];
  
  % set the corresponding colors
  window_colors = { { DK_BLUE, LT_BLUE}, ...
                    { LT_RED,  DK_RED } };
  
  % make the colormap
  [map, map_limits] = make_sig_map(windows, window_colors, [], map_size);
  
  otherwise
  error('Invalid p_type.')
end

function [map,map_limits] = make_sig_map(windows,window_colors,val_range,map_size)
  %MAKE_SIG_MAP   Make a colormap to use for plotting significance.
  %
  %  map = make_sig_map(windows,window_colors,val_range,map_size)
  %
  %  INPUTS:
  %        windows:  cell array of 1X2 vectors, where windows{i}(1) gives
  %                  the starting value of window i, and windows{i}(2)
  %                  gives the end value of window i.
  %
  %  window_colors:  cell array of colors (in RGB format) corresponding
  %                  to each window. Each cell can either contain a single
  %                  color or a 1X2 cell array of colors, indicating start
  %                  and end colors for a gradient.
  %
  %      val_range:  range of values that will correspond to the full
  %                  color map. Default is [windows{1}(1) windows{end}(2)].
  %
  %       map_size:  integer indicating the size of the color map. Use
  %                  larger values for higher resolution. Default: 128.
  %
  %  OUTPUTS:
  %            map:  a color map. Areas that were not specified in the
  %                  windows but are within val_range are colored white.

  % input checks
  if ~exist('windows','var')
    error('You must specify values to map the colors onto.')
    elseif ~exist('window_colors','var')
    error('You must specify colors for the endpoints of each window.')
  end
  if ~exist('val_range','var') || isempty(val_range)
    % use the first value in the first window
    % to the last value in the last window
    val_range = [windows{1}(1) windows{end}(2)];
  end
  if ~exist('map_size','var')
    map_size = 128;
  end

  % initialize as a white map
  map = ones(map_size,3);
  for i=1:length(windows)
    % sanity checks
    if diff(windows{i})<0
      error('window %d is not increasing.', i)
      elseif windows{i}(1)<val_range(1) || windows{i}(2)>val_range(2)
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
%endfunction

function color_index = val2color(val,val_range,map_size)
  %VAL2COLOR   Get the index in a colormap for a given value.
  %
  %  color_coord = val2color(val,val_range,map_size)
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
  x = (val-val_range(1))/diff(val_range);
  
  % translate to color space
  if x==0
    color_index = 1;
    else
    color_index = ceil(x*map_size);
  end
%endfunction
