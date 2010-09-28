function res = traintest(testpattern, trainpattern, testtargets, ...
                         traintargets, varargin)
%TRAINTEST   Train a classifier on one pattern, test it on a second.
%
%  res = traintest(testpattern, trainpattern, testtargets, traintargets, ...)
%
%  INPUTS:
%   testpattern:  An [obs X var] matrix of data to test the classifier.
%
%  trainpattern:  An [observations X variables] matrix of data to
%                 train a classifier with.
%
%   testtargets:  Ditto.
%
%  traintargets:  An [observations X conditions] matrix giving the
%                 condition corresponding to each observation.
%
%  OUTPUTS:
%       res:  Structure with results of the classification for each
%             iteration.
%  PARAMS:
%  Options can be set using property, value pairs or a structure.
%   f_train      - function handle for training a classifier
%   train_args   - args to be passed into f_train
%   f_test       - function handle a classifier
%   f_perfmet    - function handle for calculating performance
%   perfmet_args - cell array of addition arguments for the perfmet
%                  function
%
%  NOTES:
%   The counterintuitive test, then train order of inputs is necessary
%   for compatibility with apply_by_group.

if isempty(testpattern)
  res.perf = NaN;
  res.train_idx = [];
  res.test_idx = [];
  res.unused_idx = [];
  res.unknown_idx = [];
  res.targs = NaN;
  res.acts = NaN;
  res.scratchpad = NaN;
  res.train_funct_name = '';
  res.test_funct_name = '';
  res.args = NaN;
  res.perfmet.guesses = NaN;
  res.perfmet.desireds = NaN;
  res.perfmet.corrects = NaN;
  res.perfmet.perf = NaN;
  res.perfmet.scratchpad = [];
  res.perfmet.perm_perf = NaN;
  res.perfmet.function_name = '';
  return
end

% input checks
if ~exist('trainpattern', 'var') || ~isnumeric(trainpattern)
  error('You must pass training pattern matrix.')
elseif ~exist('testpattern', 'var') || ~isnumeric(testpattern)
  error('You must pass a test pattern vector.')
elseif ~exist('traintargets', 'var')
  error('You must pass a train targets matrix.')
elseif ~exist('testtargets', 'var')
  error('You must pass a test targets matrix.')
elseif size(traintargets, 1) ~= size(trainpattern, 1)
  error('Different number of observations in trainpattern and targets matrix.')
elseif size(testtargets, 1) ~= size(testpattern, 1)
  error('Different number of observations in testpattern and targets matrix.')
end

% check to make sure that pattern1 and pattern2 have same
% dimensions > 2
defaults.feature_select = false;
defaults.f_stat = @statmap_anova;
defaults.stat_args = {};
defaults.stat_thresh = 0.05;
defaults.f_train = @train_logreg;
defaults.train_args = struct('penalty', 10);
defaults.f_test = @test_logreg;
defaults.f_perfmet = {@perfmet_maxclass};
defaults.perfmet_args = struct;
defaults.save_scratchpad = true;
defaults.verbose = false;
[params, unused] = propval(varargin, defaults);

if ~iscell(params.f_perfmet)
  params.f_perfmet = {params.f_perfmet};
end
if ~isfield(params, 'perfmet_args')
  params.perfmet_args = cell(1, length(params.f_perfmet));
  params.perfmet_args{:} = deal(struct);
end
if isstruct(params.train_args)
  params.train_args = {params.train_args};
end

f_train = params.f_train;
f_test = params.f_test;

% flatten all dimensions > 2 into one vector
patsize = size(trainpattern);
if ndims(trainpattern) > 2
  trainpattern = reshape(trainpattern, [patsize(1) prod(patsize(2:end))]);
end

patsize = size(testpattern);
if ndims(testpattern) > 2
  testpattern = reshape(testpattern, [patsize(1) prod(patsize(2:end))]);
end

% optional feature selection
if params.feature_select
  p = params.f_stat(trainpattern, traintargets, params.stat_args{:});
  mask = p < params.stat_thresh;
  trainpattern = trainpattern(:,mask);
  testpattern = testpattern(:,mask);
  fprintf('selecting %d of %d features.\n', nnz(mask), prod(patsize(2:end)))
end

% deal with missing data
trainpattern = rescale(remove_nans(trainpattern));
testpattern = rescale(remove_nans(testpattern));

n_perfs = length(params.f_perfmet);
store_perfs = NaN(n_perfs);

% save data in MVPA style
n_events = size(testpattern, 1);
res.train_idx = false(n_events, 1);
res.test_idx = true(n_events, 1);
res.unused_idx = false(n_events, 1);
res.unknown_idx = [];
res.targs = testtargets';
res.train_funct_name = func2str(f_train);
res.test_funct_name = func2str(f_test);
res.args = params;

try
  % train
  scratchpad = f_train(trainpattern', traintargets', params.train_args{:});  

  % test
  testtargets = testtargets';
  [acts, scratchpad] = f_test(testpattern', testtargets, scratchpad);
  %scratchpad.cur_iteration = i;

  % calculate performance
  for p=1:n_perfs
    pm_fh = params.f_perfmet{p};
    pm = pm_fh(acts, testtargets, scratchpad, params.perfmet_args{p});
    pm.function_name = func2str(pm_fh);
    
    res.perfmet{p} = pm;
    [res.perf(p), store_perfs(p)] = deal(pm.perf);
  end
catch err
  fprintf('error in classification:\n')
  disp(getReport(err))
  res.perfmet = {struct};
  res.perf = NaN(1, n_perfs);
  res.acts = NaN(size(testtargets));
  if params.save_scratchpad
    res.scratchpad = struct;
  end
  return
end

res.acts = acts;
if params.save_scratchpad
  res.scratchpad = scratchpad;
end

% clf
% subplot(2,1,1)
% plot(res.targs')
% subplot(2,1,2)
% plot(res.acts')
% drawnow

if params.verbose
  fprintf('%.2f\t', res.perf)
  if n_perfs > 1
    fprintf('\n')
  end

  if n_perfs==1
    fprintf('\n')
  end
end
