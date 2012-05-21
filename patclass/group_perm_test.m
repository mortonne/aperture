function exp = group_perm_test(exp, pat_name, stat_name, varargin)
%GROUP_PERM_TEST   Run a permutation test on a performance metric.
%
%  exp = group_perm_test(exp, pat_name, stat_name, ...)
%
%  PARAMS:
%   n_perms   - (10000)
%   f_perfmet - (@perfmet_maxclass)
%   dist      - 0
%   memory    - '2G'
%   walltime  - '00:15:00'

% options
defaults.n_perms = 10000;
defaults.f_perfmet = @perfmet_maxclass;
[params, run_opts] = propval(varargin, defaults);

defaults = [];
defaults.dist = 0;
defaults.memory = '2G';
defaults.walltime = '00:15:00';
run_opts = propval(run_opts, defaults);

pat = getobj(exp.subj(1), 'pat', pat_name);
stat = getobj(pat, 'stat', stat_name);
res = get_stat(stat, 'res');
[n_iter, n_chan, n_time, n_freq] = size(res.iterations);

% initialize the actual and perm stats
n_subj = length(exp.subj);
perf = NaN(n_subj, n_chan, n_time, n_freq);
perf_perm = NaN(n_subj, n_chan, n_time, n_freq, params.n_perms);
for i = 1:n_subj
  fprintf('%s\n', exp.subj(i).id)
  % load the classification results
  stat = getobj(exp.subj(i), 'pat', pat_name, 'stat', stat_name);
  res = get_stat(stat, 'res');
  
  res_size = size(res.iterations);
  n_samp = prod(res_size(2:end));
  n_cond = size(res.iterations(1).targs, 1);
  shuffles = make_perms(params.n_perms, n_cond);  
  %acts = NaN([n_cond res_size(2:end)]);
  %targs = NaN([n_cond res_size(2:end)]);
  all_ind = repmat({':'}, 1, 4);
  for j = 1:n_samp
    ind = all_ind;
    [ind{2:end}] = ind2sub(res_size(2:end), j);
    [acts, targs] = get_class_stats(res.iterations(ind{:}));
    
    % calculate actual and permuted performance
    perfmet = perfmet_perm(acts, targs, struct, ...
                           'scramble_inds', shuffles, ...
                           'perfmet_fcn', params.f_perfmet);
    ind{1} = i;    
    perf(ind{:}) = perfmet.perf;
    perf_perm(ind{:}, :) = perfmet.perm_perf;
  end
end

% average over subjects
perf = nanmean(perf, 1);
perf_perm = nanmean(perf_perm, 1);

% pool over samples to make the null distribution
p = NaN(size(perf));
for i = 1:numel(perf)
  if isnan(perf(i))
    continue
  end
  
  % combine z_perm values over all bins to control for familywise
  % type I error rate
  p(i) = nnz(perf_perm(~isnan(perf_perm)) >= perf(i)) ...
         / numel(~isnan(perf_perm));
  if p(i) == 0
    p(i) = 1 / numel(perf_perm);
  end
end

% save in a new stat file
stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', stat_name, 'group'));
stat = init_stat(stat_name, stat_file, 'group', params);
set_stat(stat, 'perf', perf, 'perf_perm', perf_perm, 'p', p);

% create a pattern with performance values
exp.subj = apply_to_pat(exp.subj, pat_name, @create_perf_pattern, ...
                        {stat_name, 'stat_type', params.f_perfmet, ...
                         'event_bins', 'overall', ...
                         'save_mats', false, ...
                         'save_as', 'temp', 'overwrite', true}, ...
                        run_opts.dist, rmfield(run_opts, 'dist'));

% average over subjects
pat = grand_average(exp.subj, 'temp', ...
                    'save_as', [pat_name '-' stat_name], 'overwrite', true);

% remove the temp pattern
exp.subj = apply_to_subj(exp.subj, @rmobj, {'pat', 'temp'});

% save the average pattern with the stats
pat = setobj(pat, 'stat', stat);
exp = setobj(exp, 'pat', pat);

