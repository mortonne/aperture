function closeFile(filename)
%
%CLOSEFILE   Closes a file after processing is done.
%   CLOSEFILE(FILENAME) checks if FILENAME.lock exists, and runs
%   releaseFile on it if it does.
%

% if the file was locked, remove the lockfile
if exist([filename '.lock'], 'file')
  releaseFile(filename);
end
