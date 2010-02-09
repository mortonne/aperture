function exp = update_exp(exp, log)
%UPDATE_EXP   Save changes to the exp structure.
%
%  exp = update_exp(exp, log)
%
%  INPUTS:
%      exp:  an experiment structure. Must have 'resDir'
%            and 'file' fields.
%
%      log:  optional string describing the changes made since the last
%            version of exp.
%
%  OUTPUTS:
%      exp:  the experiment structure, with the lastUpdate
%            field updated.

% input checks
if ~exist('exp','var') || ~isstruct(exp)
  error('You must pass an experiment structure.')
elseif ~isfield(exp, 'file')
  error('exp must have a "file" field.')
elseif ~isfield(exp, 'resDir')
  error('exp must have a "resDir" field.')
end
if ~exist('log', 'var')
  log = '';
end

backup_dir = fullfile(exp.resDir, 'exp_bak');
if ~exist(backup_dir, 'dir')
  mkdir(backup_dir);
end

fprintf('update_exp: ');

timestamp = datestr(now, 'mm-dd-yy_HHMM');
if exist(exp.file, 'file')
  % save a backup of the old exp
  filename = sprintf('exp_%s.mat', timestamp);
  backup_file = fullfile(backup_dir, filename);
  copyfile(exp.file, backup_file);
  fprintf('backed up in %s...', filename)
else
  % exp hasn't been saved in exp.file before
  if ~exist(exp.resDir, 'dir')
    error('Directory does not exist: %s', exp.resDir)
  end
  if isempty(log)
    log = sprintf('creating %s experiment object', get_obj_name(exp));
  end
end

% update the lastUpdate field
exp.lastUpdate = timestamp;

% commit the new version of exp
save(exp.file, 'exp', 'log');

fprintf('saved.\n');
