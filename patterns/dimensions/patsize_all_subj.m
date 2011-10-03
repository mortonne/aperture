function pat_size = patsize_all_subj(subj, pat_name)
%PATSIZE_ALL_SUBJ   Get the size of a pattern for all subjects.
%
%  pat_size = patsize_all_subj(subj, pat_name)
%
%  INPUTS:
%      subj:  vector of subject objects.
%
%  pat_name:  name of a pattern defined for all subjects.
%
%  OUTPUTS:
%  pat_size:  [subjects X 4] vector giving the size of each subject's
%             pattern matrix.

n_subj = length(subj);
pat_size = NaN(n_subj, 4);
for i = 1:n_subj
  pat = getobj(subj(i), 'pat', pat_name);
  pat_size(i,:) = patsize(pat.dim);
end

