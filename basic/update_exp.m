function exp = update_exp(exp,backup_dir)
%UPDATE_EXP   Save changes to the exp structure.
%
%  exp = update_exp(exp, backup_dir)
%
%  INPUTS:
%         exp:  an experiment structure. Must have 'resDir'
%               and 'file' fields.
%
%  backup_dir:  path to the directory where a backup of the
%               exp structure will be saved. Default:
%               [exp.resDir]/'exp_bak'
%
%  OUTPUTS:
%         exp:  the experiment structure, with the lastUpdate
%               field updated.

% input checks
if ~exist('exp','var') || ~isstruct(exp)
  error('You must pass an experiment structure.')
elseif ~isfield(exp, 'file')
  error('exp must have a "file" field.')
elseif ~isfield(exp, 'resDir')
  error('exp must have a "resDir" field.')
end
if ~exist('backup_dir','var')
  backup_dir = fullfile(exp.resDir, 'exp_bak');
end
if ~exist(backup_dir,'dir')
  mkdir(backup_dir);
end

fprintf('update_exp: ');

% if running on the cluster, take possession of exp first
if ~isfield(exp, 'useLock')
  exp.useLock = 1;
end

if exp.useLock
  if ~lockFile(exp.file, 1);
    error('locking timed out.')
  end
  fprintf('locked...');
end

if exist(exp.file, 'file')
  % save a backup of the old exp
  timestamp = datestr(now, 'mm-dd-yy_HHMM');
  filename = sprintf('exp_%s.mat', timestamp);
  backup_file = fullfile(backup_dir, filename);
  copyfile(exp.file, backup_file);
  fprintf('backed up in %s...', filename)
else
  % exp hasn't been saved in exp.file before
  if ~exist(exp.resDir,'dir')
    mkdir(exp.resDir)
  end
end

% update the lastUpdate field
exp.lastUpdate = timestamp;

% commit the new version of exp
save(exp.file, 'exp');
closeFile(exp.file);

fprintf('saved.\n');
