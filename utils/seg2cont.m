function [new_pattern, pat_size] = seg2cont(pattern)

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

[n_events, n_chans, n_samps] = size(pattern);

%make pattern eventsXtimeXchan
pattern = permute(pattern, [1 3 2]);
%pattern = permute(pattern, [3 1 2]);

%unravel pattern so columns are channels and rows go from E1T1 to
%E2T1 to E(end-1)Tend to EendTend
new_pattern = reshape(pattern, n_events * n_samps, n_chans);

% now if there are n events and m samples:
%% E1T1 E1T2 ... E1Tm E2T1 E2T2 ... E2Tm ... EnTm
%new_pattern = reshape(pattern, n_events * n_samps, n_chans);



