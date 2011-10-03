function [freqbins,freqbinlabels] = freq_bands2()
%FREQ_BANDS2   Bin definitions for standard frequency bands.
%
%  [freqbins, freqbinlabels] = freq_bands2()

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

freqbins = [2 4; 4 8.1; 10 14; 16 25; 25 55; 65 128];
freqbinlabels = {'Delta', 'Theta', 'Alpha', 'Beta', 'Low Gamma', 'High Gamma'};
