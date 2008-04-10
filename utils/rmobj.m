function exp = rmobj(exp, query, varargin)

% get the latest copy of exp
load(exp.file);

% delete the object and any files attached to it
exp = recursive_rmfield(exp, query, varargin);

% make a backup and update exp
exp = update_exp(exp);
