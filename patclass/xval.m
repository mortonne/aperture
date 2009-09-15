function res = xval(pattern, selector, targets, params)
%XVAL   Use cross-validation to test a classifier.
%
%  res = xval(pattern, selector, targets, params)
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
%    params:  Structure whose fields give options for classifying the
%             data.  See below.
%
%  OUTPUTS:
%       res:  Structure with results of the classification for each
%             iteration.

% input checks
if ~exist('pattern', 'var') || ~isnumeric(pattern)
  error('You must pass a pattern matrix.')
elseif ~exist('selector', 'var') || ~isnumeric(selector)
  error('You must pass a selector vector.')
elseif ~isvector(selector)
  error('Selector must be a vector.')
elseif length(selector) ~= size(pattern, 1)
  error('Different number of observations in pattern and selector.')
elseif ~exist('targets', 'var') || ~isnumeric(targets)
  error('You must pass a targets vector.')
elseif length(targets) ~= size(pattern, 1)
  error('Different number of observations in pattern and targets vector.')
end
if ~exist('params', 'var')
  params = []
end

params = structDefaults(params,                   ...
                        'f_train', @train_logreg, ...
                        'f_test',  @test_logreg,  ...
                        'f_perfmet', {@perfmet_maxclass});
if ~iscell(params.f_perfmet)
  params.f_perfmet = {params.f_perfmet};
end
if ~isfield(params, 'perfmet_args')
  params.perfmet_args = cell(1, length(params.f_perfmet));
  params.perfmet_args{:} = deal(struct);
end

% get the selector value for each iteration
sel_vals = unique(selector);
sel_vals = sel_vals(~isnan(sel_vals));
if length(sel_vals) < 2
  error('Selector must have at least two unique non-NaN values.')
end

f_train = params.f_train;
f_test = params.f_test;

% flatten all dimensions > 2 into one vector
patsize = size(pattern);
if ndims(pattern)>2
  pattern = reshape(pattern, [patsize(1) prod(patsize(2:end))]);
end

pattern = remove_nans(pattern);

n_iter = length(sel_vals);
n_perfs = length(params.f_perfmet);
store_perfs = NaN(n_iter, n_perfs);
for i=1:n_iter
  
  % find the observations to train and test on
  train_idx = selector ~= sel_vals(i);
  test_idx = selector == sel_vals(i);
  unused_idx = isnan(selector);
  
  % train
  scratchpad = f_train(pattern(train_idx,:)', targets(train_idx,:)', params);
  
  % test
  test_targets = targets(test_idx,:)';
  [acts, scratchpad] = f_test(pattern(test_idx,:)', test_targets, scratchpad);
  scratchpad.cur_iteration = i;
  
  % calculate performance
  for p=1:n_perfs
    pm_fh = params.f_perfmet{p};
    pm = pm_fh(acts, test_targets, scratchpad, params.perfmet_args{p});
    pm.function_name = func2str(pm_fh);
    
    iter_res.perfmet{p} = pm;
    [iter_res.perf(p), store_perfs(i,p)] = deal(pm.perf);
  end

  % save data from this iteration in MVPA style
  iter_res.train_idx = train_idx;
  iter_res.test_idx = test_idx;
  iter_res.unused_idx = unused_idx;
  iter_res.unknown_idx = [];
  iter_res.targs = test_targets;
  iter_res.acts = acts;
  iter_res.scratchpad = scratchpad;
  iter_res.train_funct_name = func2str(f_train);
  iter_res.test_funct_name = func2str(f_test);
  iter_res.args = params;
  res.iterations(i) = iter_res;

  fprintf('%.2f\t', res.iterations(i).perf)
  if n_perfs > 1
    fprintf('\n')
  end
end

if n_perfs==1
  fprintf('\n')
end

