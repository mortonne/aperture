function [p, f] = statmap_anova(pattern, targets)
%STATMAP_ANOVA   Create a one-way ANOVA statmap.
%
%  [p, f] = statmap_anova(pattern, targets)
%
%  INPUTS:
%  pattern:  [observations X variables] matrix.
%
%  targets:  [observations X conditions] logical array specifying the
%            condition of each observation.
%
%  OUTPUTS:
%        p:  [1 X variables] array of p-values.
%
%        f:  [1 X variables] array of F statistics.

% translate regressors to group format
[i, group] = find(targets);

% create the statmap
n_var = size(pattern, 2);
p = NaN(1, n_var);
f = NaN(1, n_var);
for i=1:n_var
  [p(i), anovatab, stats] = anova1(pattern(:,i), group, 'off');
  f(i) = anovatab{2,5};
end

