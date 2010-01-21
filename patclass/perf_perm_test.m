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
  % res: [iter X chan X time X freq X subj]
  % chan, time, and freq dimensions are singleton
  % c:   [subj X iter X field]
  c = permute(struct2cell(res), [6 2 1 3 4 5]);
  f = fieldnames(res);
  
  % get actual performance as [subj X iter]
  perf = cell2num(c(:,:,strcmp('perf', f)));
  
  % get a structure of perfmets for each subject and iteration
  all_perfmet_cell = cell2num(c(:,:,strcmp('perfmet', f)));
  perfmet = cell2num(all_perfmet_cell); % assuming one perfmet

  % get permuted performance as [subj X iter X perm]
  n_subj = size(perfmet, 1);
  n_iter = size(perfmet, 2);
  n_perm = length(perfmet(1).perm_perf);
  perm_perf = NaN(n_subj, n_iter, n_perm);
  for i=1:n_subj
    for j=1:n_iter
      % performance values for all permutations
      % may be NaN scalar if classification was not run for this bin
      x = perfmet(i,j).perm_perf;
      
      if ~isnan(x)
        perm_perf(i,j,:) = x;
      end
    end
  end
  
  % average over subjects and iterations
  obs_perf = nanmean(nanmean(perf));
  rand_perf = squeeze(nanmean(nanmean(perm_perf, 1), 2));

  % get the fraction of random performance values greater than or
  % equal to the observed value
  p = nnz(rand_perf >= obs_perf) / n_perm;
  if p==0
    p = 1 / n_perm;
  end
%endfunction

