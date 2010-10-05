function pat_dir = get_pat_dir(pat, varargin)
%GET_PAT_DIR   Get the path to a pattern's standard directory.
%
%  pat_dir = get_pat_dir(pat, s1, s2, ... sN)
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

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif ~isfield(pat, 'file')
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

% make sure the main directory exists
if ~isempty(main_dir) && ~exist(main_dir, 'dir')
  mkdir(main_dir);
end

% get the requested directory
pat_dir = fullfile(main_dir, varargin{:});

% make sure the subdirectory exists
if ~isempty(pat_dir) && ~exist(pat_dir, 'dir')
  mkdir(pat_dir)
end
