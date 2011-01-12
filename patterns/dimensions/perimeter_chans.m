function chan_numbers = perimeter_chans(cap_type)

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

if ~exist('cap_type','var')
  cap_type = 'HCGSN128';
end

switch cap_type
  case 'HCGSN128'
  % going clockwise from Nz
  chan_numbers = [17 14 8 126 1 125 119 113 107 99 94 88 81 ... % right side
                  73 68 63 56 49 48 128 127 25 21]; % left side
  
  otherwise
  error('Unknown cap type.')
end
