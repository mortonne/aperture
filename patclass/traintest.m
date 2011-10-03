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
%   f_train         - function handle for training a classifier
%   train_args      - args to be passed into f_train
%   f_test          - function handle a classifier
%   f_perfmet       - function handle for calculating performance
%   perfmet_args    - cell array of addition arguments for the perfmet
%                     function
%   train_sampling  - used if there is an unequal number of observations
%                     in the conditions:
%                      'over'  - each condition will be sampled with
%                                replacement to match the maximum number
%                                of observations in any condition
%                      'under' - conditions will be sampled without
%                                replacement to match the condition with
%                                the smallest number of observations
%                      ''      - (default) use all observations
%   train_index     - vector of length observations, where each unique
%                     value labels a group. When class_sampling is set,
%                     this will be used to determine the groups to
%                     balance. If not specified, the traintargets will
%                     be used to define groups. ([])
%   n_reps          - if train_sampling is set, gives the number of
%                     replications to run of random sampling and
%                     classification. (1000)
%   feature_select  - if true, feature selection will be used before
%                     classification. (false)
%   f_stat          - handle to a function to run feature selection.
%                     (@statmap_anova)
%   stat_args       - cell array of additional inputs to f_stat. ({})
%   stat_thresh     - alpha value for deciding whether a given feature
%                     should be included in the classification. (0.05)
%   save_scratchpad - if true, full details of the classification will
%                     be saved. (true)
%   verbose         - if true, more status will be printed. (false)
%
%  NOTES:
%   The counterintuitive test, then train order of inputs is necessary
%   for compatibility with apply_by_group.

% input checks
if ~exist('trainpattern', 'var') || ~isnumeric(trainpattern)
  error('You must pass training pattern matrix.')
elseif ~exist('testpattern', 'var') || ~isnumeric(testpattern)
  error('You must pass a test pattern vector.')
elseif ~exist('traintargets', 'var') || isempty(traintargets)
  error('You must pass a train targets matrix.')
elseif ~exist('testtargets', 'var') || isempty(traintargets)
  error('You must pass a test targets matrix.')
end

% options
defaults.f_train = @train_logreg;
defaults.train_args = struct('penalty', 10);
defaults.f_test = @test_logreg;
defaults.f_perfmet = {@perfmet_maxclass};
defaults.perfmet_args = struct;
defaults.train_sampling = '';
defaults.train_index = [];
defaults.n_reps = 1000;
defaults.feature_select = false;
defaults.f_stat = @statmap_anova;
defaults.stat_args = {};
defaults.stat_thresh = 0.05;
defaults.save_scratchpad = true;
defaults.verbose = false;
[params, unused] = propval(varargin, defaults);

% fix input formatting
if ~iscell(params.f_perfmet)
  params.f_perfmet = {params.f_perfmet};
end
if isempty(params.perfmet_args)
  params.perfmet_args = cell(1, length(params.f_perfmet));
  [params.perfmet_args{:}] = deal(struct);
elseif isstruct(params.perfmet_args)
  params.perfmet_args = {params.perfmet_args};
end
if isstruct(params.train_args)
  params.train_args = {params.train_args};
end

n_events = size(testtargets, 1);
n_perfs = length(params.f_perfmet);

% initialize the results structure
res.train_idx = false(n_events, 1);
res.test_idx = true(n_events, 1);
res.targs = testtargets';
res.acts = NaN(size(testtargets'));
res.train_funct_name = func2str(params.f_train);
res.test_funct_name = func2str(params.f_test);
res.perfmet = cell(1, n_perfs);
for i = 1:n_perfs
  perfmet.perf = NaN;
  perfmet.scratchpad = [];
  perfmet.function_name = func2str(params.f_perfmet{i});
  res.perfmet{i} = perfmet;
end
res.perf = NaN(1, n_perfs);
res.args = [];
res.scratchpad = [];

% if bad inputs, just return results with NaN perf
if isempty(testpattern) || isempty(trainpattern) || ...
   all(isnan(testpattern(:))) || all(isnan(trainpattern(:)))
  if ~params.save_scratchpad
    res = rmfield(res, {'args' 'scratchpad' ...
                        'train_funct_name' 'test_funct_name'});
    res.perfmet{1} = rmfield(res.perfmet{1}, {'scratchpad' 'function_name'});
  end
  
  return
end

if size(traintargets, 1) ~= size(trainpattern, 1)
  error('Different number of observations in trainpattern and targets matrix.')
elseif size(testtargets, 1) ~= size(testpattern, 1)
  error('Different number of observations in testpattern and targets matrix.')
end

% flatten all dimensions > 2 into one vector
trainpattern = flatten_pattern(trainpattern);
testpattern = flatten_pattern(testpattern);

% optional feature selection
if params.feature_select
  % run statistical test
  p = params.f_stat(trainpattern, traintargets, params.stat_args{:});
  mask = p < params.stat_thresh;
  
  % get significant features
  patsize = size(trainpattern);
  trainpattern = trainpattern(:,mask);
  testpattern = testpattern(:,mask);
  fprintf('selecting %d of %d features.\n', nnz(mask), prod(patsize(2:end)))
end

% find observations that have no features
train_missing = all(isnan(trainpattern), 2);
test_missing = all(isnan(testpattern), 2);
trainpattern = trainpattern(~train_missing,:);
testpattern = testpattern(~test_missing,:);

% deal with missing features, rescale each feature to be between
% 0 and 1
trainpattern = remove_nans(trainpattern);
testpattern = remove_nans(testpattern);
temp = [trainpattern; testpattern];
temp = rescale(temp);
trainpattern = temp(1:size(trainpattern,1),:);
testpattern = temp(size(trainpattern,1)+1:end,:);
clear temp

% transpose to match MVPA format
trainpattern = trainpattern';
testpattern = testpattern';
traintargets = traintargets';
testtargets = testtargets';

% for the classification, remove targets corresponding to missing
% observations
traintargets = traintargets(:,~train_missing);
testtargets = testtargets(:,~test_missing);

% under/oversample to remove effects of unequal N
% first, set the final params and create the index
if ~isempty(params.train_sampling)
  if isempty(params.train_index)
    % train_index undefined; just use the targets to define groups
    [t, params.train_index] = max(traintargets, [], 1);
  else
    % remove missing observations
    params.train_index = params.train_index(~train_missing);
  end
  
  % get the N for each group
  labels = nanunique(params.train_index);
  n = NaN(1, length(labels));
  for i = 1:length(labels)
    n(i) = nnz(params.train_index == labels(i));
  end
  
  c = num2cell(n);
  if ~isequal(c{:})
    % set the type of resampling
    switch params.train_sampling
     case 'over'
      new_n = max(n);
      replace = true;
     case 'under'
      new_n = min(n);
      replace = false;
    end
    
    % if the smallest bin has 0, cannot run classification
    if new_n == 0
      if ~params.save_scratchpad
        res = rmfield(res, {'args' 'scratchpad' ...
                            'train_funct_name' 'test_funct_name'});
        res.perfmet{1} = rmfield(res.perfmet{1}, ...
                                 {'scratchpad' 'function_name'});
      end
      return
    end
    
    % save the original train targets and pattern
    orig_traintargets = traintargets;
    orig_trainpattern = trainpattern;
    
  else
    % all N are equal; no need to resample or run multiple reps
    params.train_sampling = '';
    params.n_reps = 1;
  end
else
  params.n_reps = 1;
end

% re-initialize the acts matrix to be 3D if necessary
if params.n_reps > 1
  res.acts = NaN([size(res.acts, 1) size(res.acts, 2) params.n_reps]);
end

store_perfs = NaN(params.n_reps, n_perfs);
for i = 1:params.n_reps
  if params.n_reps > 1 && mod(i, round(params.n_reps / 10)) == 0
    fprintf('.')
  end
  
  if ~isempty(params.train_sampling)
    % create new train pattern and targets by sampling
    traintargets = [];
    trainpattern = [];
    for j = 1:length(labels)
      new_index = randsample(find(params.train_index == j), ...
                             new_n, replace);
      traintargets = [traintargets orig_traintargets(:,new_index)];
      trainpattern = [trainpattern orig_trainpattern(:,new_index)];
    end
  end
  
  try
    % train
    scratchpad = params.f_train(trainpattern, traintargets, ...
                                params.train_args{:}); 

    % test
    [acts, scratchpad] = params.f_test(testpattern, testtargets, scratchpad);
    
    % save the outputs for all events (acts for excluded events will
    % be NaN)
    res.acts(:,~test_missing,i) = acts;

    % calculate performance
    for p = 1:n_perfs
      % if multiple reps, this will just store the last rep
      pm_fh = params.f_perfmet{p};
      pm = pm_fh(acts, testtargets, scratchpad, params.perfmet_args{p});
      pm.function_name = func2str(pm_fh);
      
      res.perfmet{p} = pm;
      
      % save for later averaging over reps
      store_perfs(i,p) = pm.perf;
    end
  catch err
    fprintf('error in classification:\n')
    disp(getReport(err))
    return
  end
end

if params.n_reps > 1
  fprintf('\n')
end

res.perf = nanmean(store_perfs);

% save the scratchpad if desired
if params.save_scratchpad
  res.args = params;
  res.scratchpad = scratchpad;
else
  % remove any fields not absolutely necessary
  res = rmfield(res, {'args' 'scratchpad' ...
                      'train_funct_name' 'test_funct_name'});
  for p = 1:n_perfs
    res.perfmet{p} = rmfield(res.perfmet{p}, {'scratchpad' 'function_name'});
  end
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

