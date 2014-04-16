function [z, map, limits, crit, p_crit] = sig_colormap(p, varargin)
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

% options
def.alpha_range = [.05 .001];
def.map_size = 512;
def.dir = [];
def.map_type = 'signed';
opt = propval(varargin, def);

if isempty(opt.dir)
  opt.dir = repmat(-1, size(p));
end

% if either of our alphas are 0, make it very small
% so norminv will be defined
opt.alpha_range(opt.alpha_range == 0) = 1e-10;

switch opt.map_type
  case 'signed'
    limits = [norminv(opt.alpha_range(2)) norminv(1 - opt.alpha_range(2))];
    p_crit = [fliplr(opt.alpha_range) opt.alpha_range];
  case 'unsigned'
    limits = [norminv(opt.alpha_range(2)) 0];
    p_crit = fliplr(opt.alpha_range);
  otherwise
    error('Unknown map type: %s', opt.map_type)
end
thresh = norminv(1 - opt.alpha_range(1));

% create the map
[map, crit] = thresh_colormap(limits, thresh, opt.map_size);

% get corresponding z-values
z = NaN(size(p));
z(opt.dir == 1) = norminv(1 - p(opt.dir == 1));
z(opt.dir == -1) = norminv(p(opt.dir == -1));

z(z < limits(1)) = limits(1) + eps(limits(1));
z(z > limits(2)) = limits(2) - eps(limits(2));
