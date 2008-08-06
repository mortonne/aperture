function s = loadStruct(structFile, repStr, lock)
%
%LOADSTRUCT   Load a structure and recursively run strrep on all strings. 
%   S = LOADSTRUCT(STRUCTFILE,REPSTR,LOCK) loads a structure
%   stored in STRUCTFILE, and runs STRREP on all strings, even
%   arbitrarily nested ones. REPSTR is a cell array, with one row
%   per strrep command, where REPSTR{row,1} and REPSTR{row,2} are the
%   string to be replaced, and the replacement, respectively.
%
%   LOCK indicates whether the STRUCTFILE should be locked during
%   processing (default: 1).
%
%   loadStruct is useful for bringing a struct with file references
%   from a remote machine to a local machine (and vice-versa).
%
%   Example:
%      structfile = '/home1/mortonne/EXPERIMENTS/catFR_ltp/exp.mat';
%      repstr = {'/Volumes', '/home1'};
%      exp = loadStruct(structfile,repstr,1);
%

if ~exist('lock', 'var')
  lock = 1;
end

fprintf('In loadStruct: ')
if lock
	% we must sucessfully lock, so the file doesn't become corrupted
  if ~lockFile(structFile, 1);
    error('Locking timed out.')
  else
    fprintf('Locked...')
  end
end

% load the struct
temp = load(structFile);
fnames = fieldnames(temp);
s = temp.(fnames{1});

% do a strrep on any string in the struct
if exist('repStr', 'var') && ~isempty(repStr)
  s = recursive_strrep(s, repStr);
	if isfield(s, 'file')
	  save(s.file, 's');
	end

end

if lock
  releaseFile(structFile);
end
fprintf('Loaded.\n')
