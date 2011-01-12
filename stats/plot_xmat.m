function h = plot_xmat(X)
%PLOT_XMAT   Plot an image of a design matrix.
%
%  h = plot_xmat(X)

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

clf
[n_obs, n_reg] = size(X);

colormap(gray);
h = imagesc(X);
set(gca, 'XTick', 1:n_reg)

l = line(repmat((1:n_reg-1) + 0.5, 2, 1), repmat([0; n_obs], 1, n_reg-1));
set(l, 'Color', 'y');
axis off

