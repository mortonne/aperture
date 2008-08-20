function [pat,eid] = classify_pat(pat, params, pcname, resDir)
%CLASSIFY_PAT   Run a pattern classifier on a pattern.
%   PAT = CLASSIFY_PAT(PAT,PARAMS,PCNAME,RESDIR) runs a pattern
%   classifier specified by options in the PARAMS struct on the
%   pattern stored in PAT.  Results are stored in a "pc" object
%   named PCNAME, and saved in RESDIR/patclass.
%
%   Params:
%     'regressor'   Specifies what to use as a regressor. Is input
%                   to binEventsField to make the regressor
%     'selector'    Also input to binEventsField; specifies the
%                   scale with which the leave-one-out scheme is
%                   applied
%     'classifier'  Indicates the classifier to use
%                   (default: 'classify'). See run_classifier for
%                   available classifiers and options
%     'scramble'    If true (default is false), the regressor will
%                   be scrambled before classification
%                   (for debugging purposes)
%     'lock'        If true (default is false), pc.file will be
%                   locked during processing
%     'overwrite'   If true (default), existing files will be
%                   overwritten
%
%   Example:
%    params = struct('regressor','recalled', 'selector','list');
%    pat = classify_pat(pat,params,'sme');
%    

if ~exist('resDir', 'var')
	resDir = fileparts(fileparts(pat.file));
end
if ~exist('pcname', 'var')
	pcname = 'patclass';
end
if ~isfield(params, 'regressor')
	error('You must specify a regressor in params.')
end
if ~isfield(params, 'selector')
	error('You must specify a selector in params.')
end

params = structDefaults(params, 'classifier','classify', 'nComp',[], 'scramble',0, 'lock',0, 'overwrite',1, 'loadSingles',1, 'select_test',1);

status = 0;

% set where the results will be saved
filename = sprintf('%s_%s_%s.mat', pat.name, pcname, pat.source);
pcfile = fullfile(resDir, 'patclass', filename);

% check input files and prepare output files
eid = prepFiles(pat.file, pcfile, params);
if eid
  return
end

% initialize the pc object
pc = init_pc(pcname, pcfile, params);

% load the pattern and corresponding events
[pattern, events] = loadPat(pat, params);

% get the regressor to use for classification
reg.vec = binEventsField(events, params.regressor);
reg.vals = unique(reg.vec);

% optional scramble to use as a sanity check
if params.scramble
  fprintf('scrambling regressors...')
  reg.vec = reg.vec(randperm(length(reg.vec)));
end

% get the selector
sel.vec = binEventsField(events, params.selector);
sel.vals = unique(sel.vec);

% flatten all dimensions after events into one vector
patsize = size(pattern);
if length(patsize)>2
  pattern = reshape(pattern, [patsize(1) prod(patsize(2:end))]);
end

% deal with any nans in the pattern (variables may be thrown out)
pattern = remove_nans(pattern);

if params.select_test
  nTestEv = length(events)/length(sel.vals);
else
  nTestEv = length(events);
end

fprintf('running %s classifier...', params.classifier)
pcorr = NaN(1,length(sel.vals));
class = NaN(length(sel.vals),nTestEv);
posterior = NaN(length(sel.vals),nTestEv,length(reg.vals));
fprintf('\nPercent Correct:\n')
for j=1:length(sel.vals)
  if iscell(sel.vals)
    fprintf('%s:\t', sel.vals{j})
    match = strcmp(sel.vec,sel.vals{j});
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
  trainpat = pattern(trainsel,:);
  testpat = pattern(testsel,:);

  % get the corresponding regressors for train and test
  trainreg = reg.vec(trainsel);
  testreg = reg.vec(testsel);

  % run classification algorithms
  [class(j,:),err,posterior(j,:,:)] = run_classifier(trainpat,trainreg,testpat,testreg,params.classifier,params);

  % check the performance
  pcorr(j) = sum(testreg==class(j,:))/length(testreg);
  fprintf('%.4f\n', pcorr(j))
end % selector

meanpcorr = mean(pcorr);

save(pc.file, 'class', 'pcorr', 'meanpcorr', 'posterior');
closeFile(pc.file);

% add the pc object to pat
pat = setobj(pat,'pc',pc);
