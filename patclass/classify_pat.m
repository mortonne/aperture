function pat = classify_pat(pat, stat_name, varargin)
%CLASSIFY_PAT   Run a pattern classifier on a pattern.
%
%  pat = classify_pat(pat, stat_name, ...)
%
%  INPUTS:
%        pat:  a pattern object.
%
%  stat_name:  name of the stat object that will be created to hold
%              results of the analysis. Default: 'patclass'
%
%  OUTPUTS:
%        pat:  modified pattern object with an added stat object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   regressor    - REQUIRED - input to make_event_bins; used to create
%                  the regressor for classification.
%   selector     - REQUIRED - input to make_event_bins; used to create
%                  indices for cross-validation.
%   iter_cell    - determines which dimensions to iterate over. See
%                  apply_by_group for details. Default is to classify
%                  all pattern features at once. May also input a
%                  struct to be passed into patBins to create grouped
%                  dimensions. ({[],[],[],[]})
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
%   res_dir      - directory in which to save the classification
%                  results. Default is the pattern's stats directory.
%
%  EXAMPLES:
%   % classify a pattern by the "category" field of events, using
%   % cross-validation at the level of trials
%   params = [];
%   params.regressor = 'category'; % classify events by their category label
%   params.selector = {'session', 'trial'}; % leave-one-out by trial
%   pat = classify_pat(pat, 'patclass_cat', params);
%
%   % run the classification separately for each time bin
%   params.iter_cell = {[],[],'iter',[]};
%   pat = classify_pat(pat, 'patclass_cat_time', params);
%
%   % run seperately for each frequency band
%   params.iter_cell = struct('freqbins', freq_bands1);
%   pat = classify_pat(pat, 'patclass_cat_freq', params);

% input checks
if ~exist('pat','var') || ~isstruct(pat)
  error('You must pass a pattern object.')
end
if ~exist('stat_name', 'var')
  stat_name = 'patclass';
end

% default params
defaults.regressor = '';
defaults.selector = '';
defaults.iter_cell = cell(1, 4);
defaults.overwrite = true;
defaults.res_dir = get_pat_dir(pat, 'stats');

params = propval(varargin, defaults, 'strict', false);

if isempty(params.regressor)
  error('You must specify a regressor in params.')
elseif isempty(params.selector)
  error('You must specify a selector in params.')
end

% set where the results will be saved
stat_file = fullfile(params.res_dir, ...
                     objfilename('stat', stat_name, pat.source));

% check the output file
if ~params.overwrite && exist(stat_file, 'file')
  return
end

% dynamic grouping
if isstruct(params.iter_cell)
  [temp, params.iter_cell] = patBins(pat, params.iter_cell);
end

if ~isempty(params.iter_cell{1})
  error('Iterating and grouping is not supported for the events dimension.')
end

% initialize the stat object
stat = init_stat(stat_name, stat_file, pat.name, params);

% load the pattern and corresponding events
pattern = get_mat(pat);
events = get_dim(pat.dim, 'ev');

% get the regressor to use for classification
targets = create_targets(events, params.regressor);

% get the selector
selector = make_event_bins(events, params.selector);
if iscellstr(selector)
  selector = make_index(selector);
end

% run pattern classification separately for each value on the iter_dims
res = apply_by_group(@xval, {pattern}, params.iter_cell, ...
                     {selector, targets, params}, ...
                     'uniform_output', false);

% fix the res structure
res_size = size(res);
res_fixed_size = [length(res{1}.iterations) res_size(2:end)];

cell_vec = [res{:}];
struct_vec = [cell_vec.iterations];
res_fixed.iterations = reshape(struct_vec, res_fixed_size);
res = res_fixed;

% save the results
save(stat.file, 'res');

% add the stat object to the output pat object
pat = setobj(pat, 'stat', stat);

