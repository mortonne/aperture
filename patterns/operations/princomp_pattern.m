function pat = princomp_pattern(pat, varargin)
%PRINCOMP_PATTERN   Get principal components of a pattern.
%
%  pat = princomp_pattern(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  modified pattern object.
% 
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   n_dims    - number of principal components to include in the
%               pattern. If not specified, all components will be
%               returned. ([])
%   sig_dims  - if true, only the components determined by Bartlett's
%               test to explain a significant amount of the variance of
%               the pattern will be included. (false)
%   alpha     - alpha level to use if carrying out a Bartlett's test.
%               (0.05)
%   econ      - if true, only the components with variances that are
%               not necessarily zero. (see princomp) (true)
%   save_mats - if true, and input mats are saved on disk, modified
%               mats will be saved to disk. If false, the modified mats
%               will be stored in the workspace, and can subsequently
%               be moved to disk using move_obj_to_hd. (true)
%   overwrite - if true, existing patterns on disk will be overwritten.
%               (false)
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change. ('')
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% default params
defaults.n_dims = [];
defaults.sig_dims = false;
defaults.alpha = 0.05;
defaults.econ = true;
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @get_princomps, {params}, saveopts);

% initialize a stat object to hold results
stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', 'princomp', pat.source));
stat = init_stat('princomp', stat_file, pat.name, params);

% save the PCA results
res = pat.res;
pat = rmfield(pat, 'res');
save(stat.file, 'res')
pat = setobj(pat, 'stat', stat);

function pat = get_princomps(pat, params)
  pattern = get_mat(pat);
  
  % convert to [obs X vars] format
  pat_size = size(pattern);
  pattern = reshape(pattern, [pat_size(1) prod(pat_size(2:end))]);
  
  % deal with missing data
  pattern = remove_nans(pattern);
  
  % set econ flag
  if params.econ
    flag = {'econ'};
  else
    flag = {};
  end
  
  % run PCA
  fprintf('\nrunning PCA...')
  [coeff, score, latent, tsquared] = princomp(pattern, flag{:});

  % trim components
  if ~isempty(params.n_dims)
    % take the first n_dims components
    coeff = coeff(:, 1:params.n_dims);
    score = score(:, 1:params.n_dims);
    latent = latent(1:params.n_dims);
  elseif params.sig_dims
    % take only components that explain a significant portion of the
    % variance
    [ndim, prob, chisquare] = barttest(pattern', params.alpha);
    coeff = coeff(:, 1:ndim);
    score = score(:, 1:ndim);
    latent = latent(1:ndim);
    
    res.bartlett = struct('ndim', ndim, 'prob', prob, 'chisquare', chisquare);
  end
  fprintf('reduced from %d variables to %d components.\n', ...
          prod(pat_size(2:end)), size(score, 2))
  
  % save PCA info
  res.coeff = coeff;
  res.score = score;
  res.latent = latent;
  res.tsquared = tsquared;
  
  % update dimension info
  for i=1:size(score, 2)
    chan_info(i).number = i;
    chan_info(i).region = '';
    chan_info(i).label = sprintf('Component %d', i);
  end
  pat.dim.chan = chan_info;
  pat.dim.time = init_time();
  pat.dim.freq = init_freq();

  % set score as the new pattern
  pat = set_mat(pat, score, 'ws');
  
  % save the stats as a temporary field of pat
  pat.res = res;
%endfunction
