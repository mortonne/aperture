function pat = classify_pat(pat, params, pc_name, res_dir)
%CLASSIFY_PAT   Run a pattern classifier on a pattern.
%
%  pat = classify_pat(pat, params, pc_name, res_dir)
%
%  INPUTS:
%      pat:  a pattern object.
%
%   params:  structure with options for the classifier.  See below for
%            options.
%
%  pc_name:  string identifier of the new pattern classification object.
%
%  res_dir:  directory where results will be saved.
%
%  OUTPUTS:
%      pat:  modified pattern object with an added pc object.
%
%  PARAMS:
%   regressor  - REQUIRED - input to make_event_bins; used to create the
%                regressor for classification.
%   selector   - REQUIRED - input to make_event_bins; used to create
%                indices for cross-validation.
%   classifier - string indicating the type of classifier to use.  See
%                run_classifier for available classifiers and options.
%                Default: 'classify'
%   scramble   - boolean; if true, the regressor will be scrambled before
%                classification.  Useful for debugging.  Default: false
%   overwrite  - if true, existing pc files will be overwritten.
%                Default: false
%
%  EXAMPLE:
%   % classify based on subsequent memory
%   params = [];
%   params.regressor = 'recalled';
%
%   % cross-validate at the level of trials
%   params.selector = 'trial';
%
%   % run, and save results in a pc object name "sme"
%   pat = classify_pat(pat, params, 'sme');

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
if ~exist('pc_name', 'var')
	pc_name = 'patclass';
end
if ~exist('res_dir', 'var')
  res_dir = get_pat_dir(pat, 'patclass');
end

params = structDefaults(params, ...
                        'classifier', 'classify', ...
                        'scramble',   0,          ...
                        'lock',       0,          ...
                        'overwrite',  1,          ...
                        'select_test',1,          ...
                        'patthresh',  []);

% set where the results will be saved
filename = sprintf('%s_%s_%s.mat', pat.name, pc_name, pat.source);
pc_file = fullfile(res_dir, filename);

% check the output file
if ~params.overwrite && exist(pc_file, 'file')
  return
end

% initialize the pc object
pc = init_pc(pc_name, pc_file, params);

% load the pattern and corresponding events
pattern = load_pattern(pat, params);
events = load_events(pat.dim.ev);

% get the regressor to use for classification
reg.vec = make_event_bins(events, params.regressor);
reg.vals = unique(reg.vec);

% optional scramble to use as a sanity check
if params.scramble
  fprintf('scrambling regressors...')
  reg.vec = reg.vec(randperm(length(reg.vec)));
end

% get the selector
sel.vec = make_event_bins(events, params.selector);
sel.vals = unique(sel.vec);

% flatten all dimensions after events into one vector
patsize = size(pattern);
if length(patsize)>2
  pattern = reshape(pattern, [patsize(1) prod(patsize(2:end))]);
end

% deal with any nans in the pattern (variables may be thrown out)
if ~isempty(params.patthresh)
  pattern(abs(pattern)>params.patthresh) = NaN;
end
pattern = remove_nans(pattern);

if params.select_test
  nTestEv = length(sel.vec)/length(sel.vals);
else
  nTestEv = length(events);
end

fprintf('running %s classifier...', params.classifier)
pcorr = NaN(1, length(sel.vals));
class = NaN(length(sel.vals), nTestEv);
posterior = NaN(length(sel.vals), nTestEv, length(reg.vals));
fprintf('\nPercent Correct:\n')
for j=1:length(sel.vals)
  if iscell(sel.vals)
    fprintf('%s:\t', sel.vals{j})
    match = strcmp(sel.vec, sel.vals{j});
  else
    fprintf('%d:\t', sel.vals(j))
    match = sel.vec==sel.vals(j);
  end

  if params.select_test
    % select which events to test
    testsel = match;
    trainsel = ~testsel;
  else
    % train on this value, test on everything
    trainsel = match;
    testsel = true(size(sel.vec));
  end

  % get the training and testing patterns
  trainpat = pattern(trainsel,:,:,:);
  testpat = pattern(testsel,:,:,:);

  % get the corresponding regressors for train and test
  trainreg = reg.vec(trainsel);
  testreg(j,:) = reg.vec(testsel);

  try
    % run classification algorithms
    [class(j,:),err,posterior(j,:,:)] = run_classifier(trainpat,trainreg,testpat,testreg(j,:),params.classifier,params);
    catch
    warning('Classifier threw an error.')
  end

  % check the performance
  pcorr(j) = sum(testreg(j,:)==class(j,:))/length(testreg(j,:));
  fprintf('%.4f\n', pcorr(j))
end % selector

meanpcorr = mean(pcorr);

save(pc.file, 'class', 'pcorr', 'meanpcorr', 'posterior', 'testreg');
closeFile(pc.file);

% add the pc object to pat
pat = setobj(pat, 'pc', pc);
