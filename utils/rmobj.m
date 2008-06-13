function exp = rmobj(exp, query, varargin)

% get the latest copy of exp
load(exp.file);

% make a backup
exp = backup_exp(exp);

% delete the object and any files attached to it
exp = recursive_rmfield(exp, query, varargin);

% update exp
exp = update_exp(exp);
