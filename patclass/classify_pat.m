function pat = classify_pat(pat, params, stat_name, res_dir)
%CLASSIFY_PAT   Run a pattern classifier on a pattern.
%
%  pat = classify_pat(pat, params, stat_name, res_dir)
%
%  INPUTS:
%        pat:  a pattern object.
%
%     params:  structure with options for the classifier.  See below for
%              options.
%
%  stat_name:  string identifier of the new stat object which will hold
%              the classification results.  Default: 'patclass'
%
%    res_dir:  directory where results will be saved.  If not specified,
%              results will be saved in the pattern's stats directory.
%
%  OUTPUTS:
%        pat:  modified pattern object with an added stat object.
%
%  PARAMS:
%  Defaults are shown in parentheses.
%   regressor    - REQUIRED - input to make_event_bins; used to create
%                  the regressor for classification.
%   selector     - REQUIRED - input to make_event_bins; used to create
%                  indices for cross-validation.
%   iter_dims    - vector of which dimensions the classification
%                  should iterate over.  If empty, all features of the
%                  pattern will be used in one classification run. ([])
%   f_train      - function handle for a training function.
%                  (@train_logreg)
%   train_args   - struct with options for f_train. (struct)
%   f_test       - function handle for a testing function.
%                  (@test_logreg)
%   f_perfmet    - function handle for a function that calculates
%                  classifier performance. Can also pass a cell array
%                  of function handles, and all performance metrics will
%                  be calculated. ({@perfmet_maxclass})
%   perfmet_args - cell array of additional arguments to f_perfmet
%                  function(s). ({struct})
%   overwrite    - if true, if the stat file already exists, it will be
%                  overwritten. (true)

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass a pattern object.')
elseif ~exist('params','var') || ~isstruct(params)
  error('You must pass a params structure.')
elseif ~isfield(params, 'regressor')
  error('You must specify a regressor in params.')
elseif ~isfield(params, 'selector')
  error('You must specify a selector in params.')
end
if ~exist('stat_name', 'var')
  stat_name = 'patclass';
end
if ~exist('res_dir', 'var')
  res_dir = get_pat_dir(pat, 'stat');
end

% default params
defaults.regressor = '';
defaults.iter_dims = [];
defaults.overwrite = true;

params = propval(params, defaults, 'strict', false);

% set where the results will be saved
stat_file = fullfile(res_dir, objfilename('stat', stat_name, pat.source));

% check the output file
if ~params.overwrite && exist(stat_file, 'file')
  return
end

% initialize the stat object
stat = init_stat(stat_name, stat_file, pat.name, params);

% load the pattern and corresponding events
pattern = get_mat(pat);
events = get_dim(pat, 'ev');

% get the regressor to use for classification
targets = create_targets(events, params.regressor);

% get the selector
selector = make_event_bins(events, params.selector);
if iscellstr(selector)
  selector = make_index(selector);
end

if isempty(params.iter_dims)
  % use all features for classification
  res = xval(pattern, selector, targets, params);

  % put the iterations on the first dimension
  res.iterations = res.iterations';
else
  % run pattern classification separately for each value on the iter_dims
  res = apply_by_slice(@xval, {pattern}, params.iter_dims, ...
                       {selector, targets, params}, ...
                       'uniform_output', false);
  
  % fix the res structure
  res_size = size(res);
  res_fixed_size = [length(res{1}.iterations) res_size(2:end)];

  cell_vec = [res{:}];
  struct_vec = [cell_vec.iterations];
  res_fixed.iterations = reshape(struct_vec, res_fixed_size);
  res = res_fixed;
end

% save the results
save(stat.file, 'res');

% add the stat object to the output pat object
pat = setobj(pat, 'stat', stat);

