function res = xval_test_select(testpattern, testtargets, selector, ...
                                trainpattern, traintargets, varargin)
%XVAL_TEST_SELECT   Run cross-validation with two patterns.
%
%  Used to run feature selection on a testing set without peeking. On
%  each iteration, runs feature selection on a subset of the test
%  pattern, trains on the entire training pattern using the selected
%  features, then tests on the left out subset of the test pattern.
%
%  res = xval_test_select(testpattern, testtargets, selector, ...
%                         trainpattern, traintargets, ...)
%
%  INPUTS:
%   testpattern:  An [observations X variables] matrix of data to be
%                 classified.
%
%   testtargets:  An [observations X conditions] matrix giving the
%                 condition corresponding to each observation.
%
%      selector:  Vector of length [observations] with a unique integer
%                 for each cross-validation.  On each iteration, one of
%                 the labels will indicate the test data, and the other
%                 labels will indicate the training data.  NaNs mark
%                 data that will not be used in any iteration.
%
%  trainpattern:  [observations X variables] pattern for the training
%                 set.
%
%  traintargets:  [observations X conditions] matrix giving conditions
%                 for each observation in the training set.
%
%  OUTPUTS:
%           res:  Structure with results of the classification for each
%                 iteration.
%
%  PARAMS:
%  Options can be set using property, value pairs or a structure.
%   verbose        - if true, more output will be printed. (false)
%   feature_select - if true, feature selection will be used. (true)
%   f_stat         - handle to a function to select features.
%                    (@statmap_anova)
%   stat_args      - cell array of additional inputs to f_stat. ({})
%   stat_thresh    - alpha value for deciding whether a given feature
%                    should be included in the classification. (0.05)
%
%  NOTES:
%   The counterintuitive test, then train order of inputs is necessary
%   for compatibility with apply_by_group.

% input checks
if ~isvector(selector) || ~isnumeric(selector)
  error('Selector must be a numeric vector.')
elseif length(selector) ~= size(testpattern, 1)
  error('Different number of observations in test pattern and selector.')
elseif size(traintargets, 1) ~= size(trainpattern, 1)
  error('Different number of observations in test pattern and targets matrix.')
elseif size(testtargets, 1) ~= size(testpattern, 1)
  error('Different number of observations in train pattern and targets matrix.')
end

% options
defaults.verbose = false;
defaults.feature_select = true;
defaults.f_stat = @statmap_anova;
defaults.stat_args = {};
defaults.stat_thresh = 0.05;
[params, class_params] = propval(varargin, defaults);
class_params = propval(class_params, struct, 'strict', false);
class_params.verbose = false;

% get the selector value for each iteration
sel_vals = nanunique(selector);
n_iter = length(sel_vals);
if n_iter < 2
  error('Selector must have at least two unique non-NaN values.')
end

% flatten all dimensions > 2 into one vector
trainpattern = flatten_pattern(trainpattern);
testpattern = flatten_pattern(testpattern);

for i = 1:n_iter
  % find observations to train and test
  unused_idx = isnan(selector);
  fs_idx = ~unused_idx & (selector ~= sel_vals(i));
  test_idx = selector == sel_vals(i);
  
  % get parts of the test pattern
  fs_testpattern = testpattern(fs_idx, :);
  fs_testtargets = testtargets(fs_idx, :);
  sel_iter_testpattern = testpattern(test_idx, :);
  iter_testtargets = testtargets(test_idx, :);
  
  % copy the train pattern
  sel_trainpattern = trainpattern;
  
  % run feature selection
  if params.feature_select
    p = params.f_stat(fs_testpattern, fs_testtargets, params.stat_args{:});
    mask = p < params.stat_thresh;
    sel_trainpattern = sel_trainpattern(:, mask);
    sel_iter_testpattern = sel_iter_testpattern(:, mask);
    fprintf('selecting %d of %d features.\t', ...
            nnz(mask), size(fs_testpattern, 2))
  end
  
  % classify this iteration
  iter_res = traintest(sel_iter_testpattern, sel_trainpattern, ...
                       iter_testtargets, traintargets, class_params);
  
  % save the indices for this xval
  iter_res.train_idx = fs_idx;
  iter_res.test_idx = test_idx;
  iter_res.unused_idx = unused_idx;
  iter_res.unknown_idx = [];
  
  % save results from this iteration
  res.iterations(i) = iter_res;
  
  if params.verbose
    fprintf('%.2f\n', res.iterations(i).perf)
  end
end

if params.verbose
  fprintf('TOTAL: %.2f', nanmean([res.iterations.perf]))
else
  fprintf('%.2f', nanmean([res.iterations.perf]))
end

fprintf('\n')

