function ci = bootstrap_ci(x, n_perm)

[n_subj, n_cond] = size(x);
m = NaN(n_perm, n_cond);
for i = 1:n_perm
  ind = randsample(size(x, 1), size(x, 1), true);
  m(i,:) = nanmean(x(ind,:), 1);
end

ci = prctile(m, [2.5 97.5], 1);

