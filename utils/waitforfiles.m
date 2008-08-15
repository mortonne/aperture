function waitforfiles(files, timeLimit)
%WAITFORFILES   Wait for a set of files to be created/unlocked.
%   WAITFORFILES(FILES,TIMELIMIT) waits for file(s) in the string
%   or cell array of strings FILES to all both be created and
%   not have corresponding lockfiles.  If TIMELIMIT (default: 1 minute)
%   is reached before this happens, a timeout error is thrown.
%   TIMELIMIT is specified in seconds.
%

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
