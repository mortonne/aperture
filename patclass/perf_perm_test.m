function stat = perf_perm_test(subj, stat_path, stat_name, res_dir)
%PERF_PERM_TEST   Test significance of a permutated performance metric.
%
%  stat = perf_perm_test(subj, stat_path, stat_name, res_dir)
%
%  INPUTS:
%       subj:  vector of subject objects.
%
%  stat_path:  cell array of obj_type, obj_name pairs giving the path to
%              a stat object that contains results of permuted
%              classifier performance metrics (created by perfmet_perm).
%
%  stat_name:  name of the new stat object that will hold results of the
%              significance test.
%
%    res_dir:  directory where the results of the test will be saved.
%
%  OUTPUTS:
%       stat:  stat object with results.

% input checks
if ~exist('stat_name', 'var')
  stat_name = 'perf_perm';
end
if ~exist('params', 'var')
  params = struct;
end

% get stat objects from all subjects
stats = getobjallsubj(subj, stat_path);

res = [];
for i=1:length(stats)
  subj_res = getfield(load(stats(i).file), 'res');
  res = cat(5, res, subj_res.iterations);
end

p = apply_by_slice(@perm_test, {res}, 2:4, {});

stat = init_stat(stat_name, '', '', params);
stat.p = p;

function p = perm_test(res)
  % [subj X iter X chan X time X freq]
  res = permute(res, [5 1 2 3 4]);

  n_subj = size(res,1);
  n_iter = size(res,2);
  
  % get actual performance [subj X 1]
  perf = reshape([res.perf], [n_subj n_iter]);
  perf = nanmean(nanmean(perf));
  
  % get permuted performance
  temp = [res.perfmet];
  temp = [temp{:}];
  % get rid of NaN structs
  for i=1:length(temp)
    rem_these(i) = isnan(temp(i).perm_perf(1));
  end
  temp(rem_these) = [];
  n_subj = size(temp,2);
  n_perms = length(temp(1).perm_perf);
  temp = reshape([temp.perm_perf], [n_perms, n_subj n_iter]);

  % average over iterations and subjects
  perm_perf = nanmean(nanmean(temp, 3), 2);

  val = sort(perm_perf);
  
  p = (n_perms - nnz(perf > val)) / n_perms;
  if p==0
    p = 1 / n_perms;
  end
%endfunction

