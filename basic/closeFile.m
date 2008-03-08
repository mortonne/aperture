function closeFile(filename, varargin)
%
%CLOSEFILE - saves the specified variables in filename, and
%releases filename.lock if it exists
%

% if the file was locked, remove the lockfile
if exist([filename '.lock'], 'file')
  releaseFile(filename);
end

% save all variables specified
saveStr = ['save ' filename];
for i=1:length(varargin)
  saveStr = [saveStr ' ' varargin{i}];
end
eval(saveStr);
