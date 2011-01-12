function waitforfiles(files, timeLimit)
%WAITFORFILES   Wait for a set of files to be created/unlocked.
%   WAITFORFILES(FILES,TIMELIMIT) waits for file(s) in the string
%   or cell array of strings FILES to all both be created and
%   not have corresponding lockfiles.  If TIMELIMIT (default: 1 minute)
%   is reached before this happens, a timeout error is thrown.
%   TIMELIMIT is specified in seconds.
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

if ~exist('timeLimit','var')
	timeLimit = 60;
end
if ~iscell(files)
	files = {files};
end

tic

wait = 1;
while wait
	wait = 0;

	% check the file(s)
	for f=1:length(files)
		if ~exist(files{f}) | exist([files{f} '.lock'])
			wait = 1;
		end
	end

	% see if timed out
	if toc>=timeLimit
		error('Timeout waiting for files')
	end

end
