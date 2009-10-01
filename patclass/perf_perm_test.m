function stat = perf_perm_test(subj, stat_path, stat_name, params, res_dir)

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

p = apply_by_slice(@perm_test, {res}, 2:4, {params});

stat = init_stat(stat_name, '', '', params);
stat.p = p;

function p = perm_test(res, params)
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

