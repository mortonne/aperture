function exp = classify_pat2pat(exp, params, pcname, resDir)
%CLASSIFY_PAT2PAT   Classify a pattern by training on another pattern.
%   PAT = CLASSIFY_PAT2PAT(PAT,PARAMS,PCNAME,RESDIR) runs a pattern
%   classifier specified by options in the PARAMS struct on the
%   pattern stored in PAT.  Results are stored in a "pc" object
%   named PCNAME, and saved in RESDIR/patclass.
%
%   Params:
%     'trainpatname' REQUIRED - Specifies which pattern to train the
%                    classifier on
%     'testpatname'  REQUIRED - Specifies which pattern to test the
%                    classifier on
%     'regressor'    REQUIRED - Specifies what to use as a regressor. 
%                    Is input to binEventsField to make the regressor
%     'classifier'   Indicates the classifier to use
%                    (default: 'classify'). See run_classifier for
%                    available classifiers and options
%     'scramble'     If true (default is false), the regressor will
%                    be scrambled before classification
%                    (for debugging purposes)
%     'lock'         If true (default is false), pc.file will be
%                    locked during processing
%     'overwrite'    If true (default), existing files will be
%                    overwritten
%
%   Example:
%    params = struct('regressor','category', 'trainpatname','study_pat');
%    pat = classify_pat2pat(pat,params,'study2rec');
%

if ~exist('pcname', 'var')
	pcname = 'patclass';
end
if ~isfield(params, 'trainpatname')
	error('You must specify trainpatname in params.')
end
if ~isfield(params, 'testpatname')
	error('You must specify testpatname in params.')
end
if ~isfield(params, 'regressor')
	error('You must specify a regressor in params.')
end
if ~exist('resDir', 'var')
  % save in the testpat's directory
	resDir = fullfile(exp.resDir,'eeg',params.testpatname);
end

alpha = 0.05;

params = structDefaults(params, 'classifier','classify', 'nComp',[], 'scramble',0, 'lock',0, 'overwrite',1, 'loadSingles',1, 'select_test',1,'patthresh',[]);

rand('twister',sum(100*clock))

for s=1:length(exp.subj)
  subj = exp.subj(s);

  pat1 = getobj(subj, 'pat', params.trainpatname);
  pat2 = getobj(subj, 'pat', params.testpatname);
  if isempty(pat1) | isempty(pat2)
    fprintf('Pattern missing; skipping %s.', subj.id)
    continue
  end

  % set where the results will be saved
  filename = sprintf('%s_%s_%s.mat', pat2.name, pcname, pat2.source);
  pcfile = fullfile(resDir, 'patclass', filename);

  % check input files and prepare output files
  if prepFiles({pat1.file, pat2.file}, pcfile, params)~=0
    continue
  end

  fprintf('\n%s\n', subj.id)
  fprintf('Running classify_pat2pat...')

  % initialize the pc object
  pc = init_pc(pcname, pcfile, params);

  % get the training pattern (assumed to have only one time bin)
  [trainpatall, events] = loadPat(pat1, params);
  if ndims(trainpatall)>2
    % make into obsXvars matrix
    patsize = size(trainpatall);
    trainpatall = reshape(trainpatall, [patsize(1) prod(patsize(2:end))]);
  end

  % replace bad observations with the mean for that var
  if ~isempty(params.patthresh)
    trainpatall(abs(trainpatall)>params.patthresh)=NaN;
  end
  trainpatall = remove_nans(trainpatall);
  trainbadvar = find(all(isnan(trainpatall)));

  % get the training regressor
  trainreg.vec = binEventsField(events, params.regressor);
  trainreg.vals = unique(trainreg.vec);

  % get testing pattern
  [testpatall, events] = loadPat(pat2, params);

  % get the testing regressor
  testreg.vec = binEventsField(events, params.regressor);
  testreg.vals = unique(testreg.vec);

  if params.scramble
    trainreg.vec = trainreg.vec(randperm(length(trainreg.vec)));
    testreg.vec = testreg.vec(randperm(length(testreg.vec)));
  end

  fprintf('running %s classifier...', params.classifier)
  nTests = size(testpatall,3);
  nObs = size(testpatall,1);
  nCats = length(testreg.vals);

  % initialize
  pcorr = NaN(1,nTests);
  class = NaN(nTests,nObs);
  posterior = NaN(nTests,nObs,nCats);
  fprintf('\nPercent Correct:\n')

  % step through time bins of the test pattern
  for t=1:size(testpatall,3)
    fprintf('%s:\t', pat2.dim.time(t).label)

    testpat = testpatall(:,:,t,:);
    if ndims(testpat)>2
      % make into obsXvars matrix
      patsize = size(testpat);
      testpat = reshape(testpat, [patsize(1) prod(patsize(2:end))]);
    end
    if ~isempty(params.patthresh)
      testpat(abs(testpat)>params.patthresh)=NaN;
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
      [class(t,:),err,posterior(t,:,:)] = run_classifier(trainpat,trainreg.vec,testpat,testreg.vec,params.classifier,params);
      catch
      warning('Error in run_classifier.')
      continue
    end

    % check the performance
    pcorr(t) = sum(testreg.vec==class(t,:))/length(testreg.vec);
    fprintf('%.4f\n', pcorr(t))
  end

  meanpcorr = nanmean(pcorr);
  allsubjpcorr(s,:) = pcorr;
  if length(pcorr)>1
    [h,p] = ttest(pcorr,1/nCats,alpha,'right');
    fprintf('Mean: %.4f\n', meanpcorr)
    fprintf('ttest: p = %.4f\n', p)
  end

  save(pc.file, 'class', 'pcorr', 'meanpcorr', 'posterior');
  closeFile(pc.file);

  % add pc to pat2 in the exp struct
  pat2 = setobj(pat2,'pc',pc);
  exp.subj(s) = setobj(exp.subj(s),'pat',pat2);
end % subj

if ~exist('allsubjpcorr','var')
  return
end

gapcorr = nanmean(allsubjpcorr,1);
[h,p] = ttest(allsubjpcorr,1/nCats,alpha,'right');
fprintf('\nOverall:\n')
for t=1:length(pat2.dim.time)
  fprintf('%s:\t',pat2.dim.time(t).label)
  fprintf('%.4f\t', gapcorr(t))
  fprintf('%.4f\n', p(t))
end

% commit the changes to exp
exp = update_exp(exp);
