function exp = recover_pat(exp, pat_dir)
%RECOVER_PAT   Load a pattern object from disk.
%
%  exp = recover_pat(exp, pat_dir)
%
%  INPUTS:
%      exp:  an experiment object.
%
%  pat_dir:  directory containing subject pattern objects. The function
%            will attempt to add "obj" variables from all MAT-files in
%            the directory.
%
%  OUTPUTS:
%      exp:  experiment object with the pattern objects added to the
%            appropriate subjects.

search_dir = fullfile(pat_dir, '*.mat');
d = dir(search_dir);

for i = 1:length(d)
  filename = fullfile(pat_dir, d(i).name);
  pat = getfield(load(filename, 'obj'), 'obj');
  exp = setobj(exp, 'subj', pat.source, 'pat', pat);
end

