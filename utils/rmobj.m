function exp = rmobj(exp, varargin)
%
%RMOBJ   Remove an object from the exp struct.
%   EXP = RMOBJ(EXP,VARARGIN)
%
%   Before the object is removed, a backup is made
%   in exp.resDir/exp_bk with a timestamped filename.
%

% get the latest copy of exp
load(exp.file);

% make a backup
exp = backup_exp(exp);

% delete the object
exp = recursive_rmfield(exp, varargin);

% update exp
exp = update_exp(exp);
