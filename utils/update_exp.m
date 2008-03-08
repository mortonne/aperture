function exp = update_exp(exp, varargin)
%exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);

load(exp.file);
exp = recursive_setobj(exp, varargin);
save(exp.file);
