function res = traintest(testpattern, trainpattern, testtargets, ...
                         traintargets, varargin)
%TRAINTEST   Train a classifier on one pattern, test it on a second.
%
%  res = traintest(testpattern, trainpattern, testtargets, traintargets, ...)
%
%  INPUTS:
%  trainpattern:  An [observations X variables] matrix of data to
%                 train a classifier with.
%
%   testpattern:  An [obs X var] matrix of data to test the classifier.
%
%  traintargets:  An [observations X conditions] matrix giving the
%                 condition corresponding to each observation.
%
%   testtargets:  Ditto.
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
elseif ~exist('traintargets', 'var') || ~isnumeric(traintargets)
  error('You must pass a train targets vector.')
elseif ~exist('testtargets', 'var') || ~isnumeric(testtargets)
  error('You must pass a test targets vector.')
elseif length(traintargets) ~= size(trainpattern, 1)
  error('Different number of observations in trainpattern and targets vector.')
elseif length(testtargets) ~= size(testpattern, 1)
  error('Different number of observations in testpattern and targets vector.')
end

% check to make sure that pattern1 and pattern2 have same
% dimensions > 2
defaults.f_train = @train_logreg;
defaults.train_args = struct('penalty', 10);
defaults.f_test = @test_logreg;
defaults.f_perfmet = {@perfmet_maxclass};
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
if ndims(testpattern)>2
  testpattern = reshape(testpattern, [patsize(1) prod(patsize(2:end))]);
end

% deal with missing data
trainpattern = remove_nans(trainpattern);
testpattern = remove_nans(testpattern);

n_perfs = length(params.f_perfmet);
store_perfs = NaN(n_perfs);

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

% save data from this iteration in MVPA style
n_events = size(testpattern, 1);
res.train_idx = false(n_events, 1);
res.test_idx = true(n_events, 1);
res.unused_idx = false(n_events, 1);
res.unknown_idx = [];
res.targs = testtargets;
res.acts = acts;
res.scratchpad = scratchpad;
res.train_funct_name = func2str(f_train);
res.test_funct_name = func2str(f_test);
res.args = params;

fprintf('%.2f\t', res.perf)
if n_perfs > 1
  fprintf('\n')
end

if n_perfs==1
  fprintf('\n')
end

