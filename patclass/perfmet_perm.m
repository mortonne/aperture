function [perfmet] = perfmet_perm(acts, targs, scratchpad, varargin)
%PERFMET_PERM   Calculate a performance metric and bootstrap distribution.
%
%  perfmet = perfmet_perm(acts, targs, scratchpad, varargin)
%
%  INPUTS:
%        args:
%
%       targs:
%
%  scratchpad:
%
%  ARGS:
%   Additional inputs that can be passed as parameter, value pairs.
%    n_perms
%    perfmet_fcn
%    perfmet_args
%    scramble_type
%
%  OUTPUTS:
%     perfmet:

% input checks
defaults.n_perms = 1000;
defaults.perfmet_fcn = @perfmet_maxclass;
defaults.perfmet_args = {'ignore_1ofn', true};
defaults.scramble_type = 'label';
args = propval(varargin, defaults);

% run the perfmet on the actual data
perfmet = args.perfmet_fcn(acts, targs, scratchpad, args.perfmet_args);

% run the permutations, getting perf for each one
n_labels = size(targs,1);
n_trials = size(targs,2);
perfmet.perm_perf = NaN(1, args.n_perms);
for i=1:args.n_perms
  switch args.scramble_type
   case 'label'
    % scramble the category labels in the targs
    rand_targs = targs(randperm(n_labels),:);

   case 'targs'
    rand_targs = targs(:,randperm(n_trials));
    
   otherwise
    error('Unknown scramble type: ''%s''', args.scramble_type)
  end
  
  % run the performance metric on the scrambled data
  temp_perfmet = args.perfmet_fcn(acts, rand_targs, scratchpad, ...
                                  args.perfmet_args);
  
  % to keep the data size reasonable, save only the perf
  perfmet.perm_perf(i) = temp_perfmet.perf;
end


