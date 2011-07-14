function exp = group_pcorr_perm_test(exp, pat_name, stat_name)
%GROUP_PCORR_PERM_TEST   Group-level permutation test on classifier accuracy.
%
%  exp = group_pcorr_perm_test(exp, pat_name, stat_name)
%
%  INPUTS:
%        exp:  experiment object.
%
%   pat_name:  name of pattern with classifier performance.
%
%  stat_name:  name of stat object where results of subject-level
%              permutation are saved.

% load z and z_perm from the individual permutation tests
[z, z_perm] = getvarallsubj(exp.subj, {'pat', pat_name, 'stat', stat_name}, ...
                            {'z' 'z_perm'}, 5);

% average over subjects
z = nanmean(z, 5);
z_perm = nanmean(z_perm, 5);

p = NaN(size(z));
for i = 1:numel(z)
  if isnan(z(i))
    continue
  end
  
  % combine z_perm values over all bins to control for familywise
  % type I error rate
  p(i) = nnz(z_perm(~isnan(z_perm)) >= z(i)) / numel(~isnan(z_perm));
  if p(i) == 0
    p(i) = 1 / numel(z_perm);
  end
end

% create a stat object
subj_pat = getobj(exp.subj(1), 'pat', pat_name);
stat_file = fullfile(get_pat_dir(subj_pat, 'stats'), ...
                     objfilename('stat', stat_name, exp.experiment));
stat = init_stat(stat_name, stat_file, exp.experiment);

% save the individual p-value; also save z and z_perm for computing
% group-level stats
set_stat(stat, 'p', p, 'z', z, 'z_perm', z_perm);

% create a grand average performance pattern
pat = grand_average(exp.subj, pat_name, 'overwrite', true);
pat = setobj(pat, 'stat', stat);
exp = setobj(exp, 'pat', pat);

