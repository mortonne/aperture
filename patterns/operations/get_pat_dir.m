function pat_dir = get_pat_dir(pat, subdir)
%GET_PAT_DIR   Get the path to a pattern's standard directory.
%
%  pat_dir = get_pat_dir(pat, subdir)
%
%  It is assumed that the pattern's files are saved in
%  [pat_dir]/patterns.
%
%  INPUTS:
%      pat:  a pattern object.
%
%   subdir:  string name of a subdirectory of the pattern's
%            main directory to return. If subdir does not
%            exist, it will be made. Default: ''
%
%  OUTPUTS:
%  pat_dir:  path to the requested pattern directory.
%
%  EXAMPLE:
%   % get the path to the standard directory for a pattern's
%   % reports
%   report_dir = get_pat_dir(pat, 'reports');

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif ~isfield(pat,'file')
  error('pat must have a "file" field.')
end
if ~exist('subdir','var')
  subdir = '';
end

% get one of this pattern's files
if iscell(pat.file)
  pat_file = pat.file{1};
else
  pat_file = pat.file;
end

main_dir = fileparts(fileparts(pat_file));
if ~exist(main_dir,'dir')
  mkdir(main_dir);
end

% get the requested directory
pat_dir = fullfile(main_dir, subdir);

% make sure it exists
if ~exist(pat_dir,'dir')
  mkdir(pat_dir)
end
