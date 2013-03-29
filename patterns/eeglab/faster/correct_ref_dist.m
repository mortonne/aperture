function y = correct_ref_dist(pol_dist, x)
%CORRECT_REF_DIST   Correct for distance from reference.
%
%  y = correct_ref_dist(pol_dist, x)
%
%  INPUTS:
%  pol_dist:  polar distance between the reference electrode and
%             each recording electrode.
%
%         x:  some statistic based on data at each electrode. x(i)
%             gives the value at an electrode that is pol_dist(i) from
%             the reference electrode.
%
%  OUTPUTS:
%         y:  corrected stat, taken as the residuals from a
%             quadratic fit to x vs. polar distance.

% Copyright (C) 2013 Neal W Morton, Vanderbilt University
%
% Based on code from channel_properties.m in this project.
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% sorted distances
[s_pol_dist, dist_inds] = sort(pol_dist);

% indices to get from sorted order back to input order
[~, idist_inds] = sort(dist_inds);

% fit a quadratic model
p = polyfit(s_pol_dist, x(dist_inds), 2);

% calculate predicted values for the electrode distances
fitcurve = polyval(p, s_pol_dist);

% subtract to get corrected values
y = x - fitcurve(idist_inds);

