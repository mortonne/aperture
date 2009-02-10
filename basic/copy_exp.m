function exp = copy_exp(exp,resdir)
%COPY_EXP   Make a copy of an exp structure.
%   EXP = COPY_EXP(EXP,RESDIR) saves a copy of the exp structure EXP
%   in resdir/exp.mat.  

% change the resdir field
exp.resDir = resdir;

% change the file field that indicates the .mat file where exp is saved
exp.file = fullfile(resdir,'exp.mat');

% update
exp = update_exp(exp);
