function exp = classify_pat(exp, params, resDir, ananame)
%
%CLASSIFY_PAT - for a given field in the events struct, train and
%test a pattern classifier using a leave-one-out method
%
% FUNCTION: exp = classify_pat(exp, params, resDir, ananame)
%
% INPUT: exp - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the exp struct to train on),
%                 regressor (name of field in events struct to use in
%                 training the classifier), selector (name of field
%                 to use as a selector)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern)
%        resDir - 'pclass' files are saved in resDir/data
%        ananame - analysis name to save under in the exp struct
%
% OUTPUT: new exp struct with ana object added, which contains file
% info and parameters of the analysis
%

if ~isfield(params, 'patname')
  error('You must provide names of the a pattern to classify')
end
if ~isfield(params, 'regressor')
  error('You must provide the name of a regressor field to use for classification')
end
if ~isfield(params, 'selector')
  error('You must provide the name of a selector field to use for classification')
end

params = structDefaults(params, 'eventFilter', '',  'masks', {},  'scramble');

for s=1:length(exp.subj)
  pat = getobj(exp.subj(s), 'pat', params.patname);
  
  % set where the results will be saved
  pcfile = fullfile(resDir, 'patclass', [params.patname '_' exp.subj(s).id '.mat']);
  
  % check input files and prepare output files
  if prepFiles(pat.file, pcfile, params)~=0
    continue
  end
  
  fprintf('\nStarting pattern classification for %s...\n', exp.subj(s).id);

  % initialize the pc object
  pc = init_pc(pcname, pcfile, pat, params);
  
  [pattern, events] = loadPat(pcname, pcfile, pat, params);
  reg.vec = getStructField(events, params.regressor);
  reg.vals = unique(reg.vec);
  
  sel.vec = getStructField(events, params.selector);
  sel.vals = unique(sel.vec);
  
  % if this entire subject was thrown out, skip
  if length(find(isnan(pattern)))==length(find(pattern))
    continue
  end
  
  for t=1:length(pat.dim.time)
    fprintf('%s: ', pat.dim.time(t).label);
    
    for f=1:length(pat.dim.freq)
      if isfield(params, 'binFreq')
	fprintf('\n      %s:\t', pat.dim.freq(f).label);
      end
      
      % remove events that were thrown out
      thispat = squeeze(pattern(:,:,b,f));
      good = max(~isnan(thispat),[],2);
      
      thispat = thispat(good,:);
      reg.goodvec = reg.vec(good);
      sel.goodvec = sel.vec(good);
      
      tot_test_targmat = [];
      tot_test_targvec = [];
      tot_output = [];
      tot_guesses = [];
      
      for j=1:length(sel.vals)
	% select which events to test
	testsel = sel.goodvec==sel.vals(j);
	
	trainpat = thispat(~testsel,:);
	testpat = thispat(testsel,:);
	
	% deal with NaN's in the patterns
	[trainpat, testpat] = prep_patclass(trainpat, testpat);
	
	train.targvec = reg.goodvec(~testsel)';
	test.targvec = reg.goodvec(testsel)';
	for k=1:length(reg.vals)
	  train.targmat(:,k) = train.targvec==reg.vals(k);
	  test.targmat(:,k) = test.targvec==reg.vals(k);
	end
	
	% run classification algorithms
	pclassParams.nHidden = 10;
	sp1 = train_bp_netlab(train.pat',train.targmat',pclassParams);
	[output, sp2] = test_bp_netlab(test.pat',test.targmat',sp1);
	[vals, guesses] = max(output);
	tot_output = [tot_output; output'];
	tot_guesses = [tot_guesses; guesses'];
	
	% pclassParams.penalty = .5;
% 	sp1 = train_logreg(train.pat', train.targmat', pclassParams);
% 	[output sp2] = test_logreg(test.pat', test.targmat', sp1);
% 	[vals, guesses] = max(output);
% 	tot_output{i} = [tot_output{i}; output'];
% 	tot_guesses{i} = [tot_guesses{i}; guesses'-1];
% 	i = i + 1;
	
	% pclass(2).guesses = pclassify(test.pat, train.pat, train_targvec, 'mahalanobis');
% 	pclass(3).guesses = pclassify(test.pat, train.pat, train_targvec, 'linear');
% 	pclass(4).guesses = pclassify(test.pat, train.pat, train_targvec, 'quadratic');	
% 	pclass(5).guesses = pclassify(test.pat, train.pat, train_targvec, 'diagLinear');		
% 	pclass(6).guesses = pclassify(test.pat, train.pat, train_targvec, 'diagQuadratic');
	
	%guesses = SVM(train_patterns, train_targets,
        %test_patterns, pclassParams);

	tot_test_targmat = [tot_test_targmat; test.targmat];
	tot_test_targvec = [tot_test_targvec; test.targvec];
	
      end % selector

      % stats
      for i=1%:2
	right = tot_output(logical(tot_test_targmat));
	wrong = tot_output(~logical(tot_test_targmat));
	%[h, pclass(i).rw_p(b,f)] = ttest(right', wrong', .05, 'right');
	pclass(i).rmean(b,f) = nanmean(right);
	pclass(i).wmean(b,f) = nanmean(wrong);
	
	[pclass(i).rho(b,f) pclass(i).rhosig(b,f)] = corr(tot_output(:,1), tot_test_targmat(:,1));
	
	pclass(i).pcorr(b,f) = sum(tot_guesses==tot_test_targvec)/length(tot_guesses);

	fprintf('%.4f ', pclass(i).pcorr(b,f));
      end

      fprintf('\n');
      
    end % freq
    
  end % bin
  
  save(ana.file, 'pclass');
  %releaseFile(ana.file);

end % subj