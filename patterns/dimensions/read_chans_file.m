function channels = read_chans_file(file)
%READ_CHANS_FILE   Read in a standard channels file.
%
%  channels = read_chans_file(file)
%
%  INPUTS:
%      file:  path to a text file containing channel numbers.
%             There should be one channel per row. The file
%             may contain shell-style comments (i.e. everything
%             on a line after a "#" will be ignored).
%
%  OUTPUTS:
%  channels:  vector of channel numbers.

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
if ~exist('file','var')
  error('You must pass the path to a bad channels file.')
elseif ~exist(file,'file')
  error('file does not exist: %s', file)
end

fid = fopen(file);

% read the file, omitting shell-style comments
c = textscan(fid, '%d', 'CommentStyle', '#');
channels = c{1};

fclose(fid);
