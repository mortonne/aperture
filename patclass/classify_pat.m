function eeg = classify_pat(eeg, params, resDir, ananame)
%
%CLASSIFY_PAT - for a given field in the events struct, train and
%test a pattern classifier using a leave-one-out method
%
% FUNCTION: eeg = classify_pat(eeg, params, resDir, ananame)
%
% INPUT: eeg - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the eeg struct to train on),
%                 regressor (name of field in events struct to use in
%                 training the classifier), selector (name of field
%                 to use as a selector)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern)
%        resDir - 'pclass' files are saved in resDir/data
%        ananame - analysis name to save under in the eeg struct
%
% OUTPUT: new eeg struct with ana object added, which contains file
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
if ~isfield(params, 'subjects')
  params.subjects = getStructField(eeg.subj, 'id');
end

params = structDefaults(params, 'eventFilter', '',  'masks', {});

% write all file info and update the eeg struct
for n=1:length(params.subjects)
  s = find(inStruct(eeg.subj, 'strcmp(id, varargin)', params.subjects{n}));
  
  ana.name = ananame;
  ana.file = fullfile(resDir, 'data', [ananame '_' eeg.subj(s).id '.mat']);
  ana.pat = getobj(eeg.subj(s), 'pat', params.patname);
  ana.params = params;
  
  eeg.subj(s) = setobj(eeg.subj(s), 'ana', ana);
end
save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');

for s=1:length(exp.subj)
  s = find(inStruct(eeg.subj, 'strcmp(id, varargin)', params.subjects{n}));
  fprintf('\n%s\n', eeg.subj(s).id);
  
  ana = getobj(eeg.subj(s), 'ana', ananame);
  
  % if ~lockFile(ana.file) | exist([ana.pat.file '.lock'], 'file') | ~exist(ana.pat.file, 'file')
%     continue
%   end
  
  [pattern, events] = loadPat(ana.pat.file, params.masks, ana.pat.eventsFile, params.eventFilter);
  reg.vec = getStructField(events, params.regressor);
  reg.vals = unique(reg.vec);
  
  sel.vec = getStructField(events, params.selector);
  sel.vals = unique(sel.vec);
  
  % if this entire subject was thrown out, skip
  if length(find(isnan(pattern)))==length(find(pattern))
    continue
  end
  
  for b=1:size(pattern,3)
    fprintf('%d to %d ms: ', ana.pat.params.binMS{b}(1), ana.pat.params.binMS{b}(end));
    
    for f=1:size(pattern,4)
      if isfield(params, 'binFreq')
	fprintf('\n      %.1f to %.1f Hz:\t', ana.pat.params.binFreq{f}(1), ana.pat.params.binFreq{f}(end));
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
	train = struct('pat', [],  'targvec', [],  'targmat', []);
	test = struct('pat', [],  'targvec', [],  'targmat', []);
	
	% select which events to test
	testsel = sel.goodvec==sel.vals(j);
	
	train.pat = thispat(~testsel,:);
	test.pat = thispat(testsel,:);
	
	% remove channels that were thrown out for either train and test
	cboth = intersect(find(max(~isnan(train.pat))), find(max(~isnan(test.pat))));
	train.pat = train.pat(:, cboth);
	test.pat = test.pat(:, cboth);
	
	% set all other NaN's to the mean for that channel
	for x=1:length(cboth)
	  train.pat(isnan(train.pat(:,x)), x) = nanmean(train.pat(:,x));
	  test.pat(isnan(test.pat(:,x)), x) = nanmean(test.pat(:,x));	  
	end
	
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