function exp = copy_exp(exp, res_dir)
%COPY_EXP   Make a copy of an experiment object.
%
%  Makes a copy of the experiment object only. All files referenced by
%  the experiment object will stay where they are. Useful for developing
%  from an existing experiment object and associated results without
%  changing them.
%
%  exp = copy_exp(exp, res_dir)
%
%  INPUTS:
%      exp:  an experiment object.
%
%  res_dir:  path to the directory to save the copy of exp.
%
%  OUTPUTS:
%      exp:  copied experiment object, with the 'file' and 'resDir'
%            fields updated.

% input checks
if ~exist('exp', 'var') || ~isstruct(exp)
  error('You must pass an experiment object.')
elseif ~exist('res_dir', 'var') || ~ischar(res_dir)
  error('You must give the path to a results directory.')
end
if ~exist(res_dir, 'dir')
  mkdir(res_dir)
end

% change the resdir field
old_file = exp.file;
exp.resDir = res_dir;

% change the file field that indicates the .mat file where exp is saved
exp.file = fullfile(res_dir, 'exp.mat');

% save the new copy
log = sprintf('copied from %s to %s', old_file, exp.file);
exp = update_exp(exp, log);
