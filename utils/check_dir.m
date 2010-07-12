function dir = check_dir(dir)
%CHECK_DIR   Check a directory path string.
%
%  Fixes formatting issues (replaces tildes with $HOME, adds ./ if
%  necessary), creates the directory if it doesn't already exist.
%
%  dir = check_dir(dir)

% fix formatting that can cause problems
if strcmp(dir(1), '~')
  % replace tilde with $HOME
  dir = fullfile(getenv('HOME'), dir(2:end));
elseif ~ismember(dir(1), {'/', '.'})
  % if relative, make this explicit
  dir = fullfile('.', dir);
end

% make the directory if necessary
if ~exist(dir, 'dir')
  mkdir(dir)
end  

