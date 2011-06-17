function [p, f] = statmap_anova(pattern, targets)
%STATMAP_ANOVA   Create a one-way ANOVA statmap.
%
%  [p, f] = statmap_anova(pattern, targets)
%
%  INPUTS:
%  pattern:  [observations X variables] matrix.
%
%  targets:  [observations X conditions] logical array specifying the
%            condition of each observation.
%
%  OUTPUTS:
%        p:  [1 X variables] array of p-values.
%
%        f:  [1 X variables] array of F statistics.

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

% translate regressors to group format
[n_obs, n_var] = size(pattern);
group = NaN(n_obs, 1);
for i = 1:n_obs
  [temp, group(i)] = max(targets(i,:));
end

% create the statmap
p = NaN(1, n_var);
f = NaN(1, n_var);
for i = 1:n_var
  [p(i), anovatab, stats] = anova1(pattern(:,i), group, 'off');
  f(i) = anovatab{2,5};
end

