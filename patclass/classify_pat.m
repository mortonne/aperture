function [exp,pcorrall] = classify_pat(exp, params, pcname, resDir)
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

if ~exist('resDir', 'var')
	resDir = fullfile(exp.resDir, 'eeg', params.patname);
end
if ~exist('pcname', 'var')
	pcname = 'patclass';
end
if ~isfield(params, 'regressor')
	error('You must provide the name of a regressor field to use for classification')
end
if ~isfield(params, 'selector')
	error('You must provide the name of a selector field to use for classification')
end

params = structDefaults(params, 'patname', [], 'masks', {},  'eventFilter', '',  'chanFilter', '',  'classifier', 'classify',  'nComp', 150,  'scramble', 0,  'lock', 1,  'overwrite', 0,  'loadSingles', 1);
disp(params)

pcorrall = cell(length(exp.subj));
for s=1:length(exp.subj)
	pat = getobj(exp.subj(s), 'pat', params.patname);

	% set where the results will be saved
	filename = sprintf('%s_%s_%s.mat', params.patname, pcname, exp.subj(s).id);
	pcfile = fullfile(resDir, 'patclass', filename);

	% check input files and prepare output files
	if prepFiles(pat.file, pcfile, params)~=0
		continue
	end

	fprintf('\nStarting pattern classification for %s...\n', exp.subj(s).id);

	% initialize the pc object
	pc = init_pc(pcname, pcfile, params);

	% update exp
	pat = setobj(pat,'pc',pc);
	exp = update_exp(exp,'subj',exp.subj(s).id,'pat',pat);

	% load the pattern and corresponding events
	[pattern, events] = loadPat(pat, params, 1);

	% get the regressor to use for classification
	reg.vec = binEventsField(events, params.regressor);

	% optional scramble to use as a sanity check
	if params.scramble
		fprintf('scrambling regressors...')
		reg.vec = reg.vec(randperm(length(reg.vec)));
	end

	reg.vals = unique(reg.vec);

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

	if ~isempty(params.nComp)
		fprintf('getting first %d principal components...', params.nComp)
		% get principal components
		[coeff,pattern] = princomp(pattern,'econ');
		clear coeff
		pattern = pattern(:,1:params.nComp);
	end

	nTestEv = length(events)/length(sel.vals);

	fprintf('running classifier...')
	pcorr = NaN(1,length(sel.vals));
	class = NaN(length(sel.vals),nTestEv);
	posterior = NaN(length(sel.vals),nTestEv,length(reg.vals));
	fprintf('\nPercent Correct: ')
	for j=1:length(sel.vals)
		% select which events to test
		testsel = sel.vec==sel.vals(j);

		% get the training and testing patterns
		trainpat = pattern(~testsel,:);
		testpat = pattern(testsel,:);

		% get the corresponding regressors for train and test
		trainreg = reg.vec(~testsel);
		testreg = reg.vec(testsel);

		% run classification algorithms
		[class(j,:),err,posterior(j,:,:)] = run_classifier(trainpat,trainreg,testpat,testreg,params.classifier,params);

		% check the performance
		pcorr(j) = sum(testreg==class(j,:))/length(testreg);
		fprintf('%.4f ', pcorr(j))
	end % selector
	fprintf('\n');

	meanpcorr = mean(pcorr);

	save(pc.file, 'class', 'pcorr', 'meanpcorr', 'posterior');
	closeFile(pc.file);

	pcorrall{s} = pcorr;
end % subj