function exp = classify_pat2pat(exp, params, resDir, ananame)
%
%CLASSIFY_PAT_REC - for a given field in the events struct, train a
%classifier on one pattern, then test on another
%
% FUNCTION: exp = classify_pat_rec(exp, params, resDir, ananame)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname1 (specifies the name of
%                 which pattern in the exp struct to train on),
%                 patname2 (specifies which pattern to test on), field
%                 (name of field in events struct to use in
%                 training the classifier)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), scramble (if
%                 set to true, scrambles the training regressor
%                 before training - used for debugging)
%        resDir - 'pclass' files are saved in resDir/data
%        ananame - analysis name to save under in the exp struct
%
% OUTPUT: new exp struct with ana object added, which contains file
% info and parameters of the analysis
%

if ~isfield(params, 'patname1') | ~isfield(params, 'patname2')
  error('You must provide names of the two patterns to use')
end
if ~isfield(params, 'field')
  error('You must provide the name of a field to use for classification')
end

params = structDefaults(params, 'eventFilter', '',  'masks', {}, 'scramble', 0);

rand('twister',sum(100*clock))
warning('off', 'all')

for s=1:length(exp.subj)
  pat(1) = getobj(exp.subj(s), 'pat', params.patname1);
  pat(2) = getobj(exp.subj(s), 'pat', params.patname2);
  
  % set where the results will be saved
  pcfile = fullfile(resDir, 'patclass', [params.patname1 '_' params.patname2 '_' exp.subj(s).id '.mat']);
  
  % check input files and prepare output files
  if prepFiles({pat(1).file, pat(2).file}, pcfile, params)~=0
    continue
  end
  
  fprintf('\nStarting pattern classification for %s...\n', exp.subj(s).id);
  
  % initialize the pc object
  pc = init_pc(pcname, pcfile, pat, params);
  
  [trainpat, trainev] = loadPat(pat(1), params, 1);
  trainreg.vec = getStructField(trainev, params.field);
  
  [testpat, testev] = loadPat(pat(2), params, 1);
  testreg.vec = getStructField(testev, params.field);  
  
  if size(trainpat,4)~=size(testpat,4)
    error('Frequency dimension doesn''t match.');
  end
  
  % if this entire subject was thrown out, skip
  if length(find(isnan(trainpat)))==length(find(trainpat)) | length(find(isnan(testpat)))==length(find(testpat))
    continue
  end
  
  for t1=1:length(pat(1).dim.time)
    fprintf('\n%s: ', pat(1).dim.time(b1).label);
    
    for f=1:size(trainpat,4)
      if isfield(params, 'binFreq')
	fprintf('\n      %.1f to %.1f Hz:\t', pat1.params.binFreq{f}(1), pat1.params.binFreq{f}(end));
      end
      
      % remove events that were thrown out
      train_pat = squeeze(trainpat(:,:,b1,f));
      [good, col] = find(~isnan(train_pat));
      good = unique(good);
      
      train_pat = train_pat(good,:);
      train_targvec = trainreg.vec(good)';
      train_targmat = trainreg.mat(good,:);

      if scramble
	random = randperm(length(train_targvec));
	train_targvec = train_targvec(random);
	train_targmat = train_targmat(random,:);
	keyboard
      end
      
      for b2=1:size(testpat,3)
	if size(testpat,3)>1
	  fprintf('\n\t%d to %d ms: ', pat2.params.binMS{b2}(1), pat2.params.binMS{b2}(end));
	end
	
	% remove events that were thrown out
	test_pat = squeeze(testpat(:,:,b2,f));
	[good, col] = find(~isnan(test_pat));
	good = unique(good);
	
	test_pat = test_pat(good,:);
	test_targvec = testreg.vec(good)';
	test_targmat = testreg.mat(good,:);
	
	% remove channels that were thrown out for either train or test
	[row, good1] = find(~isnan(train_pat));
	[row, good2] = find(~isnan(test_pat));
	cboth = intersect(good1, good2);
	train_pat = train_pat(:,cboth);
	test_pat = test_pat(:,cboth);
	
	% set all other NaN's to the mean for that channel
	for x=1:length(cboth)
	  train_pat(isnan(train_pat(:,x)), x) = nanmean(train_pat(:,x));
	  test_pat(isnan(test_pat(:,x)), x) = nanmean(test_pat(:,x));	  
	end
	
	% run classification algorithms
	i = 1;
	
	pclassParams.penalty = .5;
	sp1 = train_logreg(train_pat', train_targmat', pclassParams);
	[output sp2] = test_logreg(test_pat', test_targmat', sp1);
	[vals, guesses] = max(output);
	tot_output{i} = output';
	tot_guesses{i} = guesses'-1;
	i = i + 1;
	
	pclassParams.nHidden = 10;
	sp1 = train_bp_netlab(train_pat',train_targmat',pclassParams);
	[output, sp2] = test_bp_netlab(test_pat',test_targmat',sp1);
	[vals, guesses] = max(output);
	tot_output{i} = output';	
	tot_guesses{i} = guesses'-1;
	i = i + 1;
	
	% stats
	for i=1:2
	  right = tot_output{i}(logical(test_targmat));
	  wrong = tot_output{i}(~logical(test_targmat));
	  [h, pclass(i).rw_p(b2,f,b1)] = ttest(right, wrong, .05, 'right');
	  pclass(i).rmean(b2,f,b1) = nanmean(right);
	  pclass(i).wmean(b2,f,b1) = nanmean(wrong);
	  
	  [pclass(i).rho(b2,f,b1) pclass(i).rhosig(b2,f,b1)] = corr(tot_output{i}(:,1), test_targmat(:,1));
	  
	  pclass(i).pcorr(b2,f,b1) = sum(tot_guesses{i}==test_targvec)/length(tot_guesses{i});
	  
	  fprintf('%.4f ', pclass(i).rw_p(b2,f,b1));
	end

      end % b2
      
    end % freq
  end % b1
  
  save(pc.file, 'pclass');
  releaseFile(pc.file);
  
end % subj