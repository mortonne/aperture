function exp = copy_exp(exp,res_dir)
%COPY_EXP   Make a copy of an experiment object.
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
if ~exist('exp','var') || ~isstruct(exp)
  error('You must pass an experiment object.')
elseif ~exist('res_dir','var') || ~ischar(res_dir)
  error('You must give the path to a results directory.')
elseif ~exist(res_dir,'dir')
  error('Directory does not exist: %s', res_dir)
end

% change the resdir field
exp.resDir = res_dir;

% change the file field that indicates the .mat file where exp is saved
exp.file = fullfile(res_dir, 'exp.mat');

% save the new copy
exp = update_exp(exp);
