function subj = classify_pat2pat(subj, params, pc_name, res_dir)
%CLASSIFY_PAT2PAT   Classify a pattern by training on another pattern.
%
%  subj = classify_pat2pat(subj, params, pc_name, res_dir)
%
%  INPUTS:
%            subj:  a subject structure.
%
%          params:  structure with fields that specify options for
%                   running the classification.  See below.
%
%         pc_name:  string identifier to use for the new "pc" object.
%                   Default: 'patclass'
%
%         res_dir:  path to the directory where results will be saved.
%                   Default is the "patclass" directory of the test
%                   pattern.
%
%  OUTPUTS:
%            subj:  subject structure with an added "pc" object.
%
%  PARAMS:
%   trainpatname - REQUIRED. string identifier of the pattern to use
%                  to train the classifier
%   testpatname  - REQUIRED. string identifier of the pattern to test 
%                  the classifier on
%   regressor    - REQUIRED. specifies how to make the regressor. See
%                  make_event_bins for valid inputs
%   classifier   - string name of the classifier to use (default:
%                  'classify').  See run_classifiers
%   scramble     - if true, the regressor will be scrambled before
%                  classification.  Useful for debugging. Default:
%                  false

% input checks
if ~exist('subj','var') || ~isstruct(subj)
  error('You must pass a subject object.')
elseif length(subj)>1
  error('subj must only contain one subject. Use apply_to_subj to run multiple subjects.')
elseif ~exist('params','var') || ~isstruct(params)
  error('You must pass a params structure.')
elseif ~isfield(params, 'trainpatname')
	error('You must specify a training pattern in params.')
elseif ~isfield(params, 'testpatname')
	error('You must specify a test pattern in params.')
elseif ~isfield(params, 'regressor')
	error('You must specify a regressor in params.')
end
if ~exist('pc_name', 'var')
	pc_name = 'patclass';
end

params = structDefaults(params, ...
                        'classifier', 'classify', ...
                        'nComp',      [],         ...
                        'scramble',   false,      ...
                        'lock',       false,      ...
                        'overwrite',  true,       ...
                        'select_test',true);

pat1 = getobj(subj, 'pat', params.trainpatname);
pat2 = getobj(subj, 'pat', params.testpatname);
if isempty(pat1) | isempty(pat2)
  error('Pattern missing.')
end

if ~exist('res_dir', 'var')
  res_dir = get_pat_dir(pat2, 'patclass');
end

rand('twister',sum(100*clock))

% set where the results will be saved
filename = sprintf('%s_%s_%s.mat', pat2.name, pc_name, pat2.source);
pc_file = fullfile(res_dir, filename);

% check the output file
if ~params.overwrite && exist(pc_file, 'file')
  return
end

% initialize the pc object
pc = init_pc(pc_name, pc_file, params);

% get the training pattern (assumed to have only one time bin)
trainpatall = load_pattern(pat1, params);
events = get_mat(pat1.dim.ev);
if ndims(trainpatall)>2
  % make into obsXvars matrix
  patsize = size(trainpatall);
  trainpatall = reshape(trainpatall, [patsize(1) prod(patsize(2:end))]);
end

% replace bad observations with the mean for that var
trainpatall = remove_nans(trainpatall);
trainbadvar = find(all(isnan(trainpatall)));

% get the training regressor
trainreg.vec = make_event_bins(events, params.regressor);
trainreg.vals = unique(trainreg.vec);

% get testing pattern
testpatall = load_pattern(pat2, params);
events = get_mat(pat2.dim.ev);

% get the testing regressor
testreg.vec = make_event_bins(events, params.regressor);
testreg.vals = unique(testreg.vec);

if params.scramble
  trainreg.vec = trainreg.vec(randperm(length(trainreg.vec)));
  testreg.vec = testreg.vec(randperm(length(testreg.vec)));
end

fprintf('running %s classifier...', params.classifier)
%nTests = size(testpatall,3);
%nObs = size(testpatall,1);
%nCats = length(testreg.vals);

[nObs, nCats, nTime, nFreq] = size(testpatall);

% initialize
pcorr = NaN(nTime, nFreq);
class = NaN(nObs, nTime, nFreq);
posterior = NaN(nObs, nCats, nTime, nFreq);
%{
pcorr = NaN(1,nTests);
class = NaN(nTests,nObs);
posterior = NaN(nTests,nObs,nCats);
%}
fprintf('\nPercent Correct:\n')

% step through time bins of the test pattern
for t=1:nTime
  for f=1:nFreq
  %fprintf('%s:\t', pat2.dim.time(t).label)

  testpat = testpatall(:,:,t,f);
  if ndims(testpat)>2
    % make into obsXvars matrix
    patsize = size(testpat);
    testpat = reshape(testpat, [patsize(1) prod(patsize(2:end))]);
  end
  testpat = remove_nans(testpat);
  testbadvar = find(all(isnan(testpat)));

  % check if PCA was done on the training pattern (will bad vars crash this?)
  if isfield(pat1.dim,'coeff') && ~isempty(pat1.dim.coeff)
    %load(pat1.dim.coeff);
    % apply the same transformation to the test pattern

  end

  trainpat = trainpatall;

  % remove variables that were all NaNs for either train or test
  toRemove = union(trainbadvar,testbadvar);
  trainpat(:,toRemove) = [];
  testpat(:,toRemove) = [];

  try
    % run classification algorithms
    %{
    [class(t,:),err,posterior(t,:,:)] = run_classifier(trainpat,trainreg.vec,testpat,testreg.vec,params.classifier,params);
    %}
    [class(:,t,f), err, posterior(:,:,t,f)] = run_classifier(trainpat, ...
                                                             trainreg.vec, ...
                                                             testpat, ...
                                                             testreg.vec, ...
                                                             params.classifier, ...
                                                             params);
  catch
    warning('Error in run_classifier.')
    continue
  end

  % check the performance
  pcorr(t,f) = sum(testreg.vec==class(:,t,f))/length(testreg.vec);
  fprintf('%.4f\n', pcorr(t,f))
end
end
%meanpcorr = nanmean(pcorr);

% for cross-fn consistency, saving testreg.vec as testreg
testreg = testreg.vec;

%save(pc.file, 'class', 'pcorr', 'meanpcorr', 'posterior','testreg');
save(pc.file, 'class', 'pcorr', 'posterior','testreg');

% add pc to pat2
pat2 = setobj(pat2, 'pc', pc);
subj = setobj(subj, 'pat', pat2);
