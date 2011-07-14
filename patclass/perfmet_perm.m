function [perfmet] = perfmet_perm(acts, targs, scratchpad, varargin)
%PERFMET_PERM   Calculate a performance metric and bootstrap distribution.
%
%  perfmet = perfmet_perm(acts, targs, scratchpad, varargin)
%
%  INPUTS:
%        acts:  [categories X observations] classifier estimates of
%               activation of each category.
%
%       targs:  [categories X observations] matrix of category labels.
%
%  scratchpad:  scratchpad struct from the classification.
%
%  OUTPUTS:
%     perfmet:  permet struct with an additional subfield called
%               perm_perf, which contains vector with performance for
%               each iteration.
%
%  PARAMS:
%   Additional inputs that can be passed as parameter, value pairs.
%    n_perms       - number of permutations to run. (1000)
%    scramble_type - level at which to scramble:
%                     'label' scramble which category is represented by
%                             which label. (default)
%                     'obs'   scramble which event corresponds to which
%                             category.
%    scramble_inds - [permutations X (label or obs)] matrix, where each
%                    row contains indices such that the scrambled targs
%                    for permutation i are
%                     rand_targs = targs(scramble_inds(i,:),:)
%                    for scrambling by label, or
%                     rand_targs = targs(:,scramble_inds(i,:))
%                    for scrambling by obs. Use this input if you want
%                    to keep the scrambling constant across different
%                    calls to this function. If not specified, scrambles
%                    will be automatically generated. ([])
%    perfmet_fcn   - handle to any perfmet function. (@perfmet_maxclass)
%    perfmet_args  - args for the perfmet. ({})

% options
defaults.n_perms = 1000;
defaults.scramble_type = 'label';
defaults.scramble_inds = [];
defaults.perfmet_fcn = @perfmet_maxclass;
%defaults.perfmet_args = {'ignore_1ofn', true};
defaults.perfmet_args = {};
args = propval(varargin, defaults);

% run the perfmet on the actual data
% exclude bad observations from the metric calculation
missing = all(isnan(acts), 1) | any(isnan(targs), 1);
if all(missing)
  perfmet = struct;
  perfmet.perf = NaN;
  if ~isempty(args.scramble_inds)
    args.n_perms = size(args.scramble_inds, 1);
  end
  perfmet.perm_perf = NaN(1, args.n_perms);
  return
else
  perfmet = args.perfmet_fcn(acts(:,~missing), targs(:,~missing), ...
                             scratchpad, args.perfmet_args);
end

% generate the scrambles
if isempty(args.scramble_inds)
  switch args.scramble_type
   case 'label'
    args.scramble_inds = randperm2(args.n_perms, size(acts, 1));
   case 'obs'
    args.scramble_inds = randperm2(args.n_perms, size(acts, 2));
   otherwise
    error('Invalid scramble type: ''%s''', args.scramble_type)
  end
else
  args.n_perms = size(args.scramble_inds, 1);
end

% run the permutations, getting perf for each one
n_labels = size(targs,1);
n_trials = size(targs,2);
perfmet.perm_perf = NaN(1, args.n_perms);
for i = 1:args.n_perms
  switch args.scramble_type
   case 'label'
    % scramble the category labels in the targs
    rand_targs = targs(args.scramble_inds(i,:),:);

   case 'obs'
    % scramble the observations
    rand_targs = targs(:,args.scramble_inds(i,:));
  end

  % exclude bad observations from the metric calculation
  missing = all(isnan(acts), 1) | any(isnan(rand_targs), 1);
  if all(missing)
    continue
  end
  
  % run the performance metric on the scrambled data
  temp_perfmet = args.perfmet_fcn(acts(:,~missing), rand_targs(:,~missing), ...
                                  scratchpad, args.perfmet_args);
  
  % to keep the data size reasonable, save only the perf
  perfmet.perm_perf(i) = temp_perfmet.perf;
end

