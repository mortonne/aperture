function fid = open_eeg_file(fileroot, channel)

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

% set the channel filename
fname = sprintf('%s.%03i', fileroot, channel);
fid = fopen(fname,'r','l'); % NOTE: the 'l' means that it
% came from a PC! 
if fid == -1
  fname = sprintf('%s%03i', fileroot, channel); % now try unpadded lead#
  fid = fopen(fname,'r','l');
end
if fid == -1
  fname = sprintf('%s.%i', fileroot, channel); % now try unpadded lead#
  fid = fopen(fname,'r','l');
end
if fid == -1
  % giving up
  error('EEG file not found for: %s channel %d.', fileroot, channel);
end
