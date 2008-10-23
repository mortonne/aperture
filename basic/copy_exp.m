function exp = copy_exp(exp,resdir)
%exp = copy_exp(exp,resdir)

exp.resDir = resdir;
exp.file = fullfile(resdir,'exp.mat');
exp = update_exp(exp);
