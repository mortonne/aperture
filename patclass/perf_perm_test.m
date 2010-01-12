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
%              significance test. Default is [stat_name]_perm.
%
%    res_dir:  directory where the results of the test will be saved.
%              Default is the parent directory of the first stat object.
%
%  OUTPUTS:
%       stat:  stat object with results.

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a vector of subject objects.')
elseif ~exist('stat_path', 'var') || ~iscellstr(stat_path)
  error('You must give the path to the stat object.')
end
if ~exist('stat_name', 'var')
  stat_name = sprintf('%s_perm', stat_path{end});
end
if ~exist('params', 'var')
  params = struct;
end
if ~exist('res_dir', 'var') || isempty(res_dir)
  stat = getobj(subj(1), stat_path{:});
  res_dir = fileparts(stat.file);
end

% get stat objects from all subjects
stats = getobjallsubj(subj, stat_path);

% load and concatenate the iterations substruct from res
res = [];
for i=1:length(stats)
  subj_res = getfield(load(stats(i).file), 'res');
  res = cat(5, res, subj_res.iterations);
end

% run the permutation test
p = apply_by_slice(@perm_test, {res}, 2:4, {});

% make a stat object to hold the results
source = sprintf('%s-%s', subj(1).id, subj(end).id);
stat_file = fullfile(res_dir, objfilename('stat', stat_name, source));
stat = init_stat(stat_name, stat_file, source, params);

save(stat.file, 'p')

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
  if n_iter==1
    % get rid of NaN structs
    % fails for multiple iterations
    for i=1:length(temp)
      rem_these(i) = isnan(temp(i).perm_perf(1));
    end
    temp(rem_these) = [];
    n_subj = size(temp,2);
  end
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

