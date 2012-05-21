function exp = group_onoff_perm_test(exp, pat_name, stat_name, varargin)
%GROUP_ONOFF_PERM_TEST   Run a permutation test of significant OnOff.
%
%  exp = group_onoff_perm_test(exp, pat_name, stat_name, ...)
%
%  PARAMS:
%   n_perms  - number of times to permute the columns of the cross-
%              correlation matrix for each subject. (10000)
%   save_on  - where to save the results of the permutation test.
%              May be:
%               'exp' - save the stat object on the experiment struct.
%               'pat' - create a pattern with performance averaged over
%                       subjects (attached to exp), then attach the stat
%                       object to that. (default)
%   dist     - flag for distributing individual subjects. (0)
%   memory   - memory for running subjects. ('2G')
%   walltime - walltime for running subjects. ('00:15:00')

% options
defaults.n_perms = 10000;
defaults.save_on = 'exp';
[params, run_opts] = propval(varargin, defaults);

defaults = [];
defaults.dist = 0;
defaults.memory = '2G';
defaults.walltime = '00:15:00';
run_opts = propval(run_opts, defaults);

% initialize the actual and perm stats
n_subj = length(exp.subj);
apply_to_pat(exp.subj, pat_name, @run_perm_subj, ...
             {stat_name, params.n_perms}, run_opts.dist, ...
             'memory', run_opts.memory, ...
             'walltime', run_opts.walltime);

% load and average over subjects
obj_path = {'pat', pat_name, 'stat', stat_name};
on_off = nanmean(getvarallsubj(exp.subj, obj_path, {'on_off'}, 5), 5);
on_off_perm = nanmean(getvarallsubj(exp.subj, obj_path, ...
                                    {'on_off_perm'}, 5), 5);

% pool over samples to make the null distribution
p = NaN(size(on_off));
for i = 1:numel(on_off)
  if isnan(on_off(i))
    continue
  end
  
  % combine z_perm values over all bins to control for familywise
  % type I error rate
  p(i) = nnz(on_off_perm(~isnan(on_off_perm)) >= on_off(i)) ...
         / numel(~isnan(on_off_perm));
  if p(i) == 0
    p(i) = 1 / numel(on_off_perm);
  end
end

% save in a new stat file
pat = getobj(exp.subj(1), 'pat', pat_name);
perm_stat_name = [pat_name '_' stat_name];
stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', perm_stat_name, 'group'));
stat = init_stat(perm_stat_name, stat_file, 'group', params);
set_stat(stat, 'on_off', on_off, 'on_off_perm', on_off_perm, 'p', p);

switch params.save_on
 case 'exp'
  exp = setobj(exp, 'stat', stat);
  
 case 'pat'
  % create a pattern with performance values
  exp.subj = apply_to_pat(exp.subj, pat_name, @create_perf_pattern, ...
                          {stat_name, 'stat_type', 'perf', ...
                           'save_mats', false, ...
                           'save_as', 'temp', 'overwrite', true}, ...
                          0, rmfield(run_opts, 'dist'));

  % average over subjects
  pat = grand_average(exp.subj, 'temp', ...
                      'save_as', [pat_name '-' stat_name], 'overwrite', true);

  % remove the temp pattern
  exp.subj = apply_to_subj(exp.subj, @rmobj, {'pat', 'temp'});

  % save the average pattern with the stats
  pat = setobj(pat, 'stat', stat);
  exp = setobj(exp, 'pat', pat);
end


function pat = run_perm_subj(pat, stat_name, n_perms)

  % load the classification results
  stat = getobj(pat, 'stat', stat_name);
  res = get_stat(stat, 'res');
  [n_iter, n_chan, n_time, n_freq] = size(res.iterations);
  
  % get cross-correlation for each sample
  xcorr_mat = class_confusion(res, 'xcorr');
  
  % calculate actual OnOff
  iter_cell = {[] [] 'iter' 'iter' 'iter'};
  on_off = permute(apply_by_group(@onoff, {xcorr_mat}, iter_cell), ...
                   [2 3 4 5 1]);

  % keep the same shuffles regardless of samples (chans, freqs, etc.)
  n_cond = size(xcorr_mat, 1);  
  shuffles = make_perms(n_perms, n_cond);
  on_off_perm = NaN(n_perms, n_chan, n_time, n_freq);
  for i = 1:n_perms
    perm_xcorr_mat = xcorr_mat(:,shuffles(i,:),:,:,:);
    on_off_perm(i,:,:,:) = apply_by_group(@onoff, {perm_xcorr_mat}, iter_cell);
  end

  % save in the same file as the classification results
  set_stat(stat, 'on_off', on_off, 'on_off_perm', on_off_perm);
  