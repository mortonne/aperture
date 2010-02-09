function exp = move_exp(exp, res_dir)
%MOVE_EXP   Move an experiment object to a new results directory.
%
%  Move an experiment object file, plus all results saved in exp.resDir,
%  and change file references in the experiment object accordingly.
%
%  exp = move_exp(exp, res_dir)
%
%  INPUTS:
%      exp:  an experiment object.
%
%  res_dir:  path to the new directory to save results in.
%
%  OUTPUTS:
%      exp:  the experiment object, with file references fixed.

% input checks
if ~exist('exp', 'var') || ~isstruct(exp)
  error('You must pass an experiment structure.')
elseif ~exist('res_dir', 'var') || ~ischar(res_dir)
  error('You must specify a new res_dir.')
end
if ~isfield(exp, 'resDir')
  error('exp must have a results directory field.')
end

% move the experiment object and all results
[status, msg, msgid] = movefile(exp.resDir, res_dir);

% fix file references in the experiment object
old_res_dir = exp.resDir;
exp = struct_strrep(exp, exp.resDir, res_dir);

% save the experiment object with the new changes
log = sprintf('moved from %s to %s', old_res_dir, res_dir);
exp = update_exp(exp, log);

