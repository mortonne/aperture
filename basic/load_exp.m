function exp = load_exp(file, backup_number)
%LOAD_EXP   Load an experiment object.
%
%  exp = load_exp(file, backup_number)
%
%  INPUTS:
%           file:  path to the experiment object's MAT-file.
%
%  backup_number:  if specified, a backup will be loaded instead of the
%                  current version. Use exp_log to determine the number
%                  of a backup.
%
%  OUTPUTS:
%            exp:  the loaded experiment object.

% input checks
if ~exist('file', 'var') || ~ischar(file)
  error('You must specify a file name.')
end
if ~exist('backup_number', 'var')
  backup_number = [];
end

if ~isempty(fileparts(file)) && ~exist(fileparts(file), 'dir')
  error('Results directory no longer exists. Cannot load exp.')
end

if ~isempty(backup_number)
  % load a backup version
  files = get_backup_files(fileparts(file));
  exp = getfield(load(files{backup_number}, 'exp'), 'exp');
else
  % load the current version
  exp = getfield(load(file, 'exp'), 'exp');
end

