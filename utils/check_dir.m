function dir = check_dir(dir)
%CHECK_DIR   Check a directory path string.
%
%  Fixes formatting issues (replaces tildes with $HOME, adds ./ if
%  necessary), creates the directory if it doesn't already exist.
%
%  dir = check_dir(dir)

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

