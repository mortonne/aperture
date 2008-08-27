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

% get subjects that are in both
[usubjs,i1,i2] = intersect({exp1.subj.id},{exp2.subj.id});

% get all unique sessions from either version of this subject
for i=1:length(usubjs)
  sess1 = exp1.subj(i1(i)).sess;
  sess2 = exp2.subj(i2(i)).sess;
  
  % find sessions that are in sess2 but not sess1
  [c,j1,j2] = setxor({sess1.dir},{sess2.dir});
  sesstoadd = sess2(j2);
  for sess=sesstoadd
    exp.subj(i1(i)) = setobj(exp.subj(i1(i)),'sess',sess);
  end
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
