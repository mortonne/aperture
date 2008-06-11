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

	if ~exist('resDir', 'var')
		resDir = fullfile(exp.resDir, 'eeg', params.patname);
	end
	if ~exist('pcname', 'var')
		pcname = 'patclass';
	end
	if ~isfield(params, 'patname1') | ~isfield(params, 'patname2')
		error('You must provide names of the two patterns to use')
	end
	if ~isfield(params, 'regressor')
		error('You must provide the name of a regressor field to use for classification')
	end
	if ~isfield(params, 'selector')
		error('You must provide the name of a selector field to use for classification')
	end

	params = structDefaults(params, 'patname', [], 'masks', {},  'eventFilter', '',  'chanFilter', '',  'classifier', 'classify',  'scramble', 0,  'lock', 1,  'overwrite', 0,  'loadSingles', 1);
	disp(params)

	rand('twister',sum(100*clock))

	for s=1:length(exp.subj)
		pat1 = getobj(exp.subj(s), 'pat', params.patname1);
		pat2 = getobj(exp.subj(s), 'pat', params.patname2);

		% set where the results will be saved
		filename = sprintf('%s_to_%s_%s_%s.mat', params.patname1, params.patname2, pcname, exp.subj(s).id);
		pcfile = fullfile(resDir, 'patclass', filename);

		% check input files and prepare output files
		if prepFiles({pat1.file, pat2.file}, pcfile, params)~=0
			continue
		end

		fprintf('\nStarting pattern classification for %s...\n', exp.subj(s).id);

		% initialize the pc object
		pc = init_pc(pcname, pcfile, params);

		% update exp
		pat2 = setobj(pat2,'pc',pc);
		exp = update_exp(exp,'subj',exp.subj(s).id,'pat',pat2);

		% get training pattern and regressor
		[trainpat, events] = loadPat(pat1, params, 1);
		trainreg.vec = binEventsField(events, params.regressor);


		% get testing pattern and regressor
		[testpat, events] = loadPat(pat2, params, 1);
		testreg.vec = binEventsField(events, params.regressor);  

		save(pc.file, 'pclass');
		releaseFile(pc.file);

	end % subj