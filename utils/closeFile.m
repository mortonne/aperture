function closeFile(filename)
%
%CLOSEFILE - saves the specified variables in filename, and
%releases filename.lock if it exists
%

% if the file was locked, remove the lockfile
if exist([filename '.lock'], 'file')
  releaseFile(filename);
end
