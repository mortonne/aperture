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
%   iter_dims  - vector of which dimensions the classification
%                should iterate over.  Default?
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
                        'iter_dims',  [],         ...
                        'scramble',   0,          ...
                        'lock',       0,          ...
                        'overwrite',  1,          ...
                        'select_test',1);

% set where the results will be saved
filename = sprintf('%s_%s_%s.mat', pat.name, pc_name, pat.source);
pc_file = fullfile(res_dir, filename);

% check the output file
if ~params.overwrite && exist(pc_file, 'file')
  return
end

% initialize the stat object
stat = init_stat(pc_name, pc_file, pat.name, params);

% load the pattern and corresponding events
pattern = load_pattern(pat, params);
events = load_events(pat.dim.ev);

% get the regressor to use for classification
targ_vec = make_event_bins(events, params.regressor);
conds = unique(targ_vec(~isnan(targ_vec)));
targets = zeros(length(events), length(conds));
for i=1:length(conds)
  cond_match = targ_vec == conds(i);
  targets(:, i) = cond_match;
end

% get the selector
selector = make_event_bins(events, params.selector);

% run pattern classification separately for each time and frequency bin
res = apply_by_slice(@xval, {pattern}, params.iter_dims, ...
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

pat = setobj(pat, 'stat', stat);

