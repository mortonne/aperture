function res = xval(pattern, selector, targets, varargin)
%XVAL   Use cross-validation to test a classifier.
%
%  res = xval(pattern, selector, targets, ...)
%
%  INPUTS:
%   pattern:  An [observations X variables] matrix of data to be
%             classified.
%
%  selector:  Vector of length [observations] with a unique integer
%             for each cross-validation.  On each iteration, one of
%             the labels will indicate the test data, and the other
%             labels will indicate the training data.  NaNs mark data
%             that will not be used in any iteration.
%
%   targets:  An [observations X conditions] matrix giving the condition
%             corresponding to each observation.
%
%  OUTPUTS:
%       res:  Structure with results of the classification for each
%             iteration.
%
%  PARAMS:
%  Options can be set using property, value pairs or a structure.
%   f_train      - function handle for training a classifier
%   train_args   - args to be passed into f_train
%   f_test       - function handle a classifier
%   f_perfmet    - function handle for calculating performance
%   perfmet_args - cell array of addition arguments for the perfmet
%                  function
%   verbose      - if true, more output will be printed. (false)

% input checks
if ~exist('pattern', 'var') || ~isnumeric(pattern)
  error('You must pass a pattern matrix.')
elseif ~exist('selector', 'var')
  error('You must pass a selector.')
elseif ~isvector(selector) || ~isnumeric(selector)
  error('Selector must be a numeric vector.')
elseif length(selector) ~= size(pattern, 1)
  error('Different number of observations in pattern and selector.')
elseif ~exist('targets', 'var')
  error('You must pass a targets matrix.')
elseif size(targets, 1) ~= size(pattern, 1)
  error('Different number of observations in pattern and targets matrix.')
end

% default params
defaults.test_targets = [];
defaults.verbose = false;
[xval_params, params] = propval(varargin, defaults);

% use propval since struct does weird things will cell array inputs
params = propval(params, struct, 'strict', false);

% override printing in traintest
params.verbose = false;

% get the selector value for each iteration
sel_vals = unique(selector);
sel_vals = sel_vals(~isnan(sel_vals));
n_sel = length(sel_vals);
if length(sel_vals) < 2
  error('Selector must have at least two unique non-NaN values.')
end
n = NaN(1, n_sel);
for i=1:n_sel
  n(i) = nnz(selector == sel_vals(i));
end
% if any(n < 10)
%   error('not enough events for each run to classify.')
% end

% flatten all dimensions > 2 into one vector
patsize = size(pattern);
if ndims(pattern) > 2
  pattern = reshape(pattern, [patsize(1) prod(patsize(2:end))]);
end

n_iter = length(sel_vals);
for i = 1:n_iter
  % find the observations to train and test on
  unused_idx = isnan(selector);
  train_idx = ~unused_idx & (selector ~= sel_vals(i));
  test_idx = selector == sel_vals(i);

  % run classification and assess performance
  if ~isempty(xval_params.test_targets)
    % use different targets for train and test (unusual)
    iter_res = traintest(pattern(test_idx,:), pattern(train_idx,:), ...
                         xval_params.test_targets(test_idx,:), ...
                         targets(train_idx,:), params);
  else
    % use targets for both train and test
    iter_res = traintest(pattern(test_idx,:), pattern(train_idx,:), ...
                         targets(test_idx,:), targets(train_idx,:), params);
  end
  
  % save the indices for this cross-validation in res
  iter_res.train_idx = train_idx;
  iter_res.test_idx = test_idx;
  iter_res.unused_idx = unused_idx;
  iter_res.unknown_idx = [];

  % all other stats come from traintest
  res.iterations(i) = iter_res;

  if xval_params.verbose
    fprintf('%.2f\t', res.iterations(i).perf)
  end
  %if n_perfs > 1
  %  fprintf('\n')
  %end
end

if xval_params.verbose
  fprintf('TOTAL: %.2f', nanmean([res.iterations.perf]))
else
  fprintf('%.2f', nanmean([res.iterations.perf]))
end

%if n_perfs==1
  fprintf('\n')
%end

