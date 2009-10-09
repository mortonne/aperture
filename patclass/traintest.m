function res = traintest(testpattern, trainpattern, testtargets, traintargets, params)
%TRAINTEST   Train a classifier on one pattern, test it on a second.
%
%  res = traintest(testpattern, trainpattern, testtargets, ...
%                  traintargets, params)
%
%  INPUTS:
%   trainpattern:  An [observations X variables] matrix of data to
%              train a classifier with.
%
%   testpattern:  An [obs X var] matrix of data to test the classifier.
%
%   traintargets:  An [observations X conditions] matrix giving the condition
%              corresponding to each observation.
%
%   testtargets:  Ditto.
%
%     params:  Structure whose fields give options for classifying the
%              data.  See below.
%
%  OUTPUTS:
%       res:  Structure with results of the classification for each
%             iteration.


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
%sel_vals = unique(selector);
%sel_vals = sel_vals(~isnan(sel_vals));
%if length(sel_vals) < 2
%  error('Selector must have at least two unique non-NaN values.')
%end

f_train = params.f_train;
f_test = params.f_test;

% flatten all dimensions > 2 into one vector
patsize = size(trainpattern);
if ndims(trainpattern)>2
  trainpattern = reshape(trainpattern, [patsize(1) prod(patsize(2:end))]);
end

patsize = size(testpattern);
if ndims(testpattern)>2
  testpattern = reshape(testpattern, [patsize(1) prod(patsize(2:end))]);
end


trainpattern = remove_nans(trainpattern);
testpattern = remove_nans(testpattern);

%n_iter = length(sel_vals);
n_perfs = length(params.f_perfmet);
store_perfs = NaN(n_perfs);
  
% find the observations to train and test on
%train_idx = selector ~= sel_vals(i);
%test_idx = selector == sel_vals(i);
%unused_idx = isnan(selector);

% train
%scratchpad = f_train(trainpattern(train_idx,:)', traintargets(train_idx,:)', params);
scratchpad = f_train(trainpattern', traintargets', params);  

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
%res.train_idx = train_idx;
%res.test_idx = test_idx;
%res.unused_idx = unused_idx;
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

