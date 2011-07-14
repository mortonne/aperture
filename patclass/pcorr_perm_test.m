function pat = pcorr_perm_test(pat, stat_name, varargin)
%PCORR_PERM_TEST   Run a permutation test on classifier percent correct.
%
%  pat = pcorr_perm_test(pat, stat_name, ...)
%
%  INPUTS:
%        pat:  pattern object.
%
%  stat_name:  name of the stat object that will be created.
%
%  OUTPUTS:
%      pat:  pattern object with a new stat object with results of the
%            permutation test.
%
%  PARAMS
%   f_perfmet     - (@perfmet_prop_test)
%   perfmet_args  - (struct)
%   n_perms       - (5000)
%   scramble_type - ('obs')
%   iter_bins     - bin definition for creating iter_index
%                   (see make_perms). ([])
%   group_bins    - bin definition for creating group_index. ([])

% options
defaults.f_perfmet = @perfmet_prop_test;
defaults.perfmet_args = struct;
defaults.n_perms = 5000;
defaults.scramble_type = 'obs';
defaults.iter_bins = [];
defaults.group_bins = [];
[params, extras] = propval(varargin, defaults);

% binning options (used both for statistic and creating perf pattern)
defaults = [];
defaults.eventbins = [];
defaults.eventbinlabels = {};
defaults.eventbinlevels = {};
defaults.chanbins = [];
defaults.chanbinlabels = {};
defaults.timebins = [];
defaults.timebinlabels = {};
defaults.freqbins = [];
defaults.freqbinlabels = {};
[bin_opts, perf_opts] = propval(extras, defaults);

% options for creating a performance pattern
defaults = [];
defaults.stat_type = @perfmet_maxclass;
defaults.event_bins = 'overall';
perf_opts = propval(perf_opts, defaults, 'strict', false);

% load classifier results
stat = getobj(pat, 'stat', stat_name);
res = get_stat(stat, 'res');
n_iter = size(res.iterations, 1);
n_class = size(res.iterations(1).targs, 1);
n_obs = patsize(pat.dim, 'ev');

params.perfmet_args.scramble_type = params.scramble_type;
switch params.scramble_type
 case 'label'
  % generate random shuffles (used for all bins)
  shuffles = randperm2(params.n_perms, n_class);
 case 'obs'
  % generate random shuffles (used for all bins)
  shuffles = randperm2(params.n_perms, n_obs);

  % use events to determine how to do scrambling
  if ~isempty(params.iter_bins) || ~isempty(params.group_bins)
    events = get_dim(pat.dim, 'ev');
  end

  % iterations to scramble within  
  if ~isempty(params.iter_bins)
    iter_index = make_event_index(events, params.iter_bins);
  else
    iter_index = [];
  end
  % groups to treat as units
  if ~isempty(params.group_bins)
    group_index = make_event_index(events, params.group_bins);
  else
    group_index = [];
  end
  shuffles = make_perms(params.n_perms, n_obs, ...
                        'iter_index', iter_index, ...
                        'group_index', group_index);
end

% create a pattern with classifier performance; useful to have mean
% performance with the stats, and generally need the pattern to have
% the same size as attached stats for plotting purposes
pat = create_perf_pattern(pat, stat_name, perf_opts);

% get the bins (need the bins cell array)
[temp, bins] = patBins(pat, bin_opts);
iter_cell = bins;
[iter_cell{cellfun(@isempty, iter_cell)}] = deal('iter');

% now apply bins as necessary; always average over all events
bin_opts.eventbins = 'overall';
bin_opts.overwrite = true;
pat = bin_pattern(pat, bin_opts);

fprintf('running permutation test...\n')
iter_cell{1} = [];
perm = apply_by_group(@perm_bin, {res.iterations}, iter_cell, ...
                      {shuffles, params}, 'uniform_output', false);
perm = cell2num(perm);

% unpack the outputs
perm_size = size(res.iterations);
binned_dims = find(~cellfun(@isempty, bins));
if ~isempty(binned_dims)
  binned_sizes = cellfun(@length, bins);
  perm_size(binned_dims) = binned_sizes(binned_dims);
end
perm_size(1) = params.n_perms;
if length(perm_size) < 4
  perm_size = [perm_size ones(1, 4 - length(perm_size))];
end

% iterations X c X t X f X fieldnames
c = permute(struct2cell(perm), [2 3 4 5 1]);
f = fieldnames(perm);
z = nanmean(cell2num(c(:,:,:,:,strcmp('z', f))), 1);
%z = NaN([1 perm_size(2:end)]);
z_perm = NaN(perm_size);
for i = 1:perm_size(2)
  for j = 1:perm_size(3)
    for k = 1:perm_size(4)
      z_perm(:,i,j,k) = perm(:,i,j,k).z_perm;
    end
  end
end

p = NaN(size(z));
for i = 1:numel(z)
  if isnan(z(i))
    continue
  end
  
  % combine z_perm values over all bins to control for familywise
  % type I error rate
  p(i) = nnz(z_perm(~isnan(z_perm)) >= z(i)) / numel(~isnan(z_perm));
  if p(i) == 0
    p(i) = 1 / numel(z_perm);
  end
end

% save the individual p-value; also save z and z_perm for computing
% group-level stats
set_stat(stat, 'p', p, 'z', z, 'z_perm', z_perm);


function perm = perm_bin(res, shuffles, params)
  % res: [iter X bin chans X bin times X bin freqs]
  
  % averaging over all bins regardless of dimension
  params.perfmet_args.perfmet_fcn = params.f_perfmet;
  params.perfmet_args.scramble_inds = shuffles;
  
  % calculate z over all iterations
  res_size = size(res);
  if length(res_size) < 4
    res_size = [res_size ones(1, 4 - length(res_size))];
  end
  z = NaN(prod(res_size(2:end)), 1);
  z_perm = NaN(prod(res_size(2:end)), params.n_perms);
  n = 0;
  for i = 1:res_size(2)
    for j = 1:res_size(3)
      for k = 1:res_size(4)
        n = n + 1;
        
        % get classifier output over all iterations
        [acts, targs] = get_class_stats(res(:,i,j,k));
        
        if all(isnan(acts(:))) || all(isnan(targs(:)))
          continue
        end
        
        % calculate actual performance and permuted performance
        perfmet = perfmet_perm(acts, targs, struct, params.perfmet_args);
        
        z(n) = perfmet.perf;
        z_perm(n,:) = perfmet.perm_perf;
      end
    end
  end
    
  % calulate averages over all samples within the bin, all iterations
  perm.z = nanmean(z);
  perm.z_perm = nanmean(z_perm, 1);
  
