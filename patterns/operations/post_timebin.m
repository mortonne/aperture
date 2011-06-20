function pat = post_timebin(pat)

%POST_TIMEBIN   fix the final timebin of a pattern after running
%               bin_pattern (in preparation for fieldtrip)
%
%
%  pat = post_timebin(pat)
%
%  INPUTS:
%        pat:  pat object 
%%
%  OUTPUTS:
%        pat:  pat object with the final timebin equal in size to
%              other timebins
%
% NOTE: the issue this deals with is that bin_pattern handles time
% binning in a way that leaves the final bin inclusive (or
% exclusive, I'm not positive); this leaves the final bin average
% or size as different than the previous bins (if you're binning
% with even time bins). fieldtrip can't handle this, or more
% specifically, the script that gets the unique time bins to get
% the sample rate (get_pat_sample_rate.m), can't handle different
% sized time bins, and so it throws an error. this script replaces
% the last time bin's value with a value equal in step size to the
% previous ones
%
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
if ~exist('pat', 'var')
  error('You must input a pattern object.')
end

times = get_dim_vals(pat.dim,'time');
step_size = unique(diff([times]));
if length(step_size)>1
  stepper = (times(end-1))- ...
            (times(end-2));
  times(end) = times(end-1)+stepper;
  warning('time bins not equal in size')
end
