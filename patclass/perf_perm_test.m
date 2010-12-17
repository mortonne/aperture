function exp = perf_perm_test(exp, stat_path, stat_name, varargin)
%PERF_PERM_TEST   Test significance of a permutated performance metric.
%
%  stat = perf_perm_test(subj, stat_path, stat_name, ...)
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
%  OUTPUTS:
%       stat:  stat object with results.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   oversample - if true, if pattern classification results have a size
%                mismatch, the smaller results will be oversampled to
%                match. (false)
%   res_dir    - directory in which to save the results. Default is the
%                parent directory of the first subject's stat file.

subj = exp.subj;

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a vector of subject objects.')
elseif ~exist('stat_path', 'var') || ~iscellstr(stat_path)
  error('You must give the path to the stat object.')
end
if ~exist('stat_name', 'var')
  stat_name = sprintf('%s_perm', stat_path{end});
end

% options
stat = getobj(subj(1), stat_path{:});
defaults.oversample = false;
defaults.res_dir = fileparts(stat.file);
[params, perm_params] = propval(varargin, defaults);
perm_params = propval(perm_params, struct, 'strict', false);

% get stat objects from all subjects
stats = getobjallsubj(subj, stat_path{:});

% load and concatenate the iterations substruct from res
res = [];
for i=1:length(stats)
  subj_res = getfield(load(stats(i).file, 'res'), 'res');
  n_iter = size(subj_res.iterations, 1);
  
  % deal with possible mismatch in number of iterations
  if n_iter < size(res, 1)
    if ~params.oversample
      error('Size mismatch. May try using oversample=true')
    end
    
    n = size(res, 1) - n_iter;
    filler = randsample(1:n_iter, n, true);
    subj_res.iterations = cat(1, subj_res.iterations, ...
                              subj_res.iterations(filler,:,:,:));
  end
  res = cat(5, res, subj_res.iterations);
end

% run the permutation test
p = apply_by_slice(@perm_test, {res}, 2:4, {perm_params});

% make a stat object to hold the results
source = sprintf('%s-%s', subj(1).id, subj(end).id);
stat_file = fullfile(params.res_dir, objfilename('stat', stat_name, source));
stat = init_stat(stat_name, stat_file, source, params);
exp = setobj(exp, 'stat', stat);

save(stat.file, 'p')

function p = perm_test(res, perm_params)
  % res: [iter X chan X time X freq X subj]
  % chan, time, and freq dimensions are singleton
  % c:   [subj X iter X field]
  
  if ~isfield(res(1).perfmet{1}, 'perm_perf')
    fprintf('running permutations...')
    parfor i = 1:numel(res)
      res(i).perfmet{1} = perfmet_perm(res(i).acts, res(i).targs, ...
                                       res(i).scratchpad, perm_params);
    end
    fprintf('done.\n')
  end
  
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
  if p == 0
    p = 1 / n_perm;
  end


