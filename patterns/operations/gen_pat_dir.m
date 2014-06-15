function pat_dir = gen_pat_dir(pat, varargin)
%GEN_PAT_DIR   Get the path to a pattern's standard directory.
%
%  Same as get_pat_dir, but does not create any directories.
%
%  pat_dir = gen_pat_dir(pat, s1, s2, ... sN)
%
%  It is assumed that the pattern's files are saved in
%  [pat_dir]/patterns.
%
%  INPUTS:
%      pat:  a pattern object.
%
%        s:  additional arguments indicate subdirectories of the main
%            pattern directory.
%
%  OUTPUTS:
%  pat_dir:  path to the requested pattern directory.
%
%  EXAMPLE:
%   % get the path to the standard directory for a pattern's
%   % figures
%   report_dir = get_pat_dir(pat, 'reports', 'figs');

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
if ~isfield(pat, 'file')
  error('pat must have a "file" field.')
end

% get one of this pattern's files
if iscell(pat.file)
  pat_file = pat.file{1};
else
  pat_file = pat.file;
end

% get the standard main directory for the pattern
main_dir = fileparts(fileparts(pat_file));

% fix the path if it is relative; assuming that we don't want to use
% filepaths relative to the search path
if ~ismember(filesep, main_dir)
  main_dir = fullfile('.', main_dir);
end

% get the requested directory
pat_dir = fullfile(main_dir, varargin{:});

% standardize the path
pat_dir = check_dir(pat_dir, false);

