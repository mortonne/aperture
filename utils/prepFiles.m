function status = prepFiles(filesToRead, filesToWrite, params)
%PREPFILES   Prepare files for use in analysis on the cluster.
%   status = prepFiles(filesToRead, filesToWrite, params) checks if
%   each file in filesToRead exists, and prepares each file in
%   filesToWrite according to options specified in the params
%   struct.  filesToRead and filesToWrite can be either strings (if
%   only one file) or cell arrays of strings (if multiple files).
%
%   Params:
%     'mkdirs'     If true (default), make the containing dir if it
%                  doesn't already exist
%     'overwrite'  If false (default true), overwriting is not allowed
%     'lock'       If true, (default false), attempt to lock each 
%                  file in filesToWrite
%     'ignoreLock' If true, (default false), first remove any 
%                  existing lockfiles
%
%   Output:
%      status - 0 if successful
%               1 if problem with one of the filesToRead
%               2 if problem with one of the filesToWrite
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

if ~exist('filesToWrite', 'var')
  filesToWrite = {};
end
if ~exist('params', 'var')
  params = struct;
end

params = structDefaults(params, 'lock', 0,  'overwrite', 1,  'mkdirs', 1,  'ignoreLock', 0);

% checking read files
status = 1;
if ischar(filesToRead)
  filesToRead = {filesToRead};
end
for f=1:length(filesToRead)
  file = filesToRead{f};
  if ~exist(file)
    % one of the files doesn't exist
    error('eeg_ana:prepFiles:fileNotFound', 'Input file %s not found.', file)
    
    elseif exist([file '.lock'], 'file')
    % one of the files is locked
    error('eeg_ana:prepFiles:fileLocked', 'Input file %s is locked.', file)
  end
end

% checking write files
status = 2;
if ischar(filesToWrite)
  filesToWrite = {filesToWrite};
end
for f=1:length(filesToWrite)
  file = filesToWrite{f};
  
  if ~exist(fileparts(file), 'dir')
    if params.mkdirs
      % make the containing directory
      mkdir(fileparts(file));
    else % the needed dir doesn't exist
      return
    end
  end
  
  if params.ignoreLock
    % sometimes the cluster can leave files unprocessed; run again
    % with one process to get them
    if exist([file '.lock'])
      releaseFile(file); % remove lockfile 
      params.overwrite = 1; % change so file can be overwritten
    end
  end
  
  if params.lock
    % lock the file if desired
    locked = lockFile(file, params.overwrite);
    if ~locked
      return
    end
    
  elseif ~params.overwrite
    % if overwriting not allowed, check if file exists
    if exist(file, 'file')
      error('eeg_ana:prepFiles:fileExists', 'Output file %s already exists.', file)
    end
  end
  
end

% if no errors
status = 0;