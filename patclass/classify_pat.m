function exp = classify_pat(exp, params, pcname, resDir)
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
	if ~isfield(params, 'pcname')
		pcname = 'patclass';
	end
	if ~isfield(params, 'regressor')
		error('You must provide the name of a regressor field to use for classification')
	end
	if ~isfield(params, 'selector')
		error('You must provide the name of a selector field to use for classification')
	end

	params = structDefaults(params, 'patname', [], 'masks', {},  'eventFilter', '',  'chanFilter', '',  'classifier', 'classify',  'scramble', 0,  'lock', 1,  'overwrite', 0);

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
		pc = init_pc(pcname, pcfile, pat, params);

		[pattern, events] = loadPat(pcname, pcfile, pat, params);
		reg.vec = binEventsField(events, params.regressor);
		reg.vals = unique(reg.vec);

		sel.vec = binEventsField(events, params.selector);
		sel.vals = unique(sel.vec);

		% if this entire subject was thrown out, skip
		if length(find(isnan(pattern)))==numel(pattern)
			continue
		end

		for t=1:length(pat.dim.time)
			fprintf('%s: ', pat.dim.time(t).label);

			for f=1:length(pat.dim.freq)
				if length(pat.dim.freq)>1
					fprintf('\n      %s:\t', pat.dim.freq(f).label);
				end

				
				thispat = squeeze(pattern(:,:,b,f));

				% remove events that were thrown out
				good = max(~isnan(thispat),[],2);

				thispat = thispat(good,:);
				reg.goodvec = reg.vec(good);
				sel.goodvec = sel.vec(good);

				for j=1:length(sel.vals)
					% select which events to test
					testsel = sel.goodvec==sel.vals(j);

					trainpat = thispat(~testsel,:);
					testpat = thispat(testsel,:);

					% deal with NaN's in the patterns
					[trainpat, testpat] = prep_patclass(trainpat, testpat);

					train.targvec = reg.goodvec(~testsel)';
					test.targvec = reg.goodvec(testsel)';

					% run classification algorithms
					[class,err,posterior] = run_classifier(trainpat,trainreg,testpat,testreg,params.classifier,params);

				end % selector
				fprintf('\n');

			end % freq
		end % bin

		save(pc.file, 'pclass');
		closeFile(pc.file);

	end % subj