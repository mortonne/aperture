function exp = merge_exps(exp1, exp2)
%MERGE_EXPS   Merge two experiment objects.
%
%  exp = merge_exps(exp1, exp2)
%
%  Merge two experiment objects, with the first experiment taking
%  precedence. See merge_subjs for details of how subject properties
%  are merged.
%
%  INPUTS:
%     exp1:  experiment object. If there are conflicts with exp2,
%            exp1 will take precedence.
%
%     exp2:  experiment object with information to add to exp1.
%
%  OUTPUTS:
%      exp:  merged experiment structure.
%
%  NOTES:
%   This function can be useful if two people are working on separate 
%   branches of an experiment structure. As long as the objects on the two
%   structures have different names, the output experiment object
%   will contain all the objects from both.
%
%   This can also be used to combine information from two experiments.
%
%  See also merge_subjs.

% to get the order of fields right
exp = exp1;

exp.subj = merge_subjs(exp1.subj, exp2.subj);

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
