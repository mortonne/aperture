function exp = merge_exps(exp1, exp2)
%MERGE_EXPS   Merge two exp structs.
%   EXP = MERGE_EXPS(EXP1,EXP2) merges exp structs EXP1 and EXP2
%   to create EXP.  If there are conflicts, EXP1 will take
%   precedence.
%

% to get the order of fields right
exp = exp1;

% get subjects that are in exp2 but not in exp1
[c,i1,i2] = setxor({exp1.subj.id},{exp2.subj.id});
subjtoadd = exp2.subj(i2);

% add them to exp
for subj = subjtoadd
  exp = setobj(exp,'subj',subj);
end

% the rest of the fields are simple precedence
fnames = union(fieldnames(exp1), fieldnames(exp2));
for i=1:length(fnames)
  f = fnames{i};
  
  if ~strcmp(f, 'subj')
    
    if isfield(exp1, f)
      exp.(f) = exp1.(f);
      
      else
      exp.(f) = exp2.(f);
    end
    
  end
end
