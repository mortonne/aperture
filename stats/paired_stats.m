function res = paired_stats(x, y, vars)
%PAIRED_STATS   Calculate various statistics on paired variables.
%
%  res = paired_stats(x, y, vars)

% describe the individual variables
res.(vars{1}) = summary_stats(x);
res.(vars{2}) = summary_stats(y);

% stats on the differences
res.diff = summary_stats(x - y);

% test for significant differences
[h, p, ci, stats] = ttest(x, y);
res.t = stats.tstat;
res.df = stats.df;
res.p = p;


function res = summary_stats(x)

  res.m = nanmean(x, 1);
  res.se = stderr(x, 1);
  if size(x, 2) > 1
    res.err = loftus_masson(x);
  end

