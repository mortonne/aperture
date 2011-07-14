function perfmet = perfmet_prop_test(acts, targs, scratchpad, varargin)
%PERFMET_PROP_TEST   Test statistic of fraction correct vs. chance.
%
%  perfmet = perfmet_prop_test(acts, targs, scratchpad, ...)

% options
defaults.chance = 1 / size(acts, 1);
[params, maxclass_opts] = propval(varargin, defaults);

% calculate fraction correct
perfmet = perfmet_maxclass(acts, targs, scratchpad, maxclass_opts);
n = size(acts, 2);

% test the hypothesis that fraction correct > chance
p = perfmet.perf;
a = params.chance;
z = (p - a) / sqrt((a * (1 - a)) / n);
perfmet.pcorr = p;
perfmet.chance = a;
perfmet.perf = z;


