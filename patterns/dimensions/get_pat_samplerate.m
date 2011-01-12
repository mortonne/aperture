function samplerate = get_pat_samplerate(pat)
%GET_PAT_SAMPLERATE   Return the samplerate of a pattern.
%
%  samplerate = get_pat_samplerate(pat)

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

ms = get_dim_vals(pat.dim, 'time');
step_size = unique(diff(ms));
if length(step_size) > 1
  error('Samplerate varies.')
end

samplerate = 1000 / step_size;

