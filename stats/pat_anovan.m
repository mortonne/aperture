function exp = pat_anovan(exp, params, statname, resDir)
	%PAT_ANOVAN   Run anovan on a pattern for individual subjects.
	%   EXP = PAT_ANOVAN(EXP,PARAMS,STATNAME,RESDIR) runs anovan on
	%   all the subjects in EXP, using options specified in PARAMS.
	%   The results are saved in a 'stat' substruct of pat named
	%   STATNAME (default is 'anovan'); p-values are saved in
	%   RESDIR/stats (default is the pat's resDir).
	%
	%   Required params:
	%      PATNAME - specifies the name of the pattern to be used.
	%                pass in [] to use the last pattern created.
	%      FIELDS - cell array that specifies how to create the
	%               regressors.  Each cell should either contain
	%               the name of an events field, or a cell array
	%               containing strings to be passed into FILTEREVENTS.
	%
	
	if ~exist('resDir', 'var')
		resDir = fullfile(exp.resDir, 'eeg', params.patname);
	end
	if ~exist('statname', 'var')
		statname = 'anovan';
	end
	if isstr(params.fields)
		params.fields = {params.fields};
	end

	params = structDefaults(params, 'patname', [],  'masks', {},  'eventFilter', '',  'chanFilter', '',  'anovan_in', {},  'factorlabels', {},  'lock', 1,  'overwrite', 0);

	for s=1:length(exp.subj)
		pat = getobj(exp.subj(s), 'pat', params.patname);

		% set where the stats will be saved
		filename = sprintf('%s_%s_%s.mat', params.patname, statname, exp.subj(s).id);
		statfile = fullfile(resDir, 'stats', filename);

		% check input files and prepare output files
		if prepFiles(pat.file, statfile, params)~=0
			continue
		end

		fprintf('\nStarting ANOVAN for %s...\n', exp.subj(s).id);

		% initialize the stat object
		stat = init_stat(statname, statfile, params);

		% load pattern and events
		[pattern, events] = loadPat(pat, params, 1);

		% make the regressors
		group = cell(1, length(params.fields));
		for i=1:length(params.fields)
			vec = binEventsField(events, params.fields{i});
			group{i} = vec';
			if ~isempty(params.factorlabels)
				stat.factor(i).name = params.factorlabels{i};
				elseif isstr(params.fields{i})
				stat.factor(i).name = params.fields{i};
				else
				stat.factor(i).name = sprintf('factor%d', i);
			end
			stat.factor(i).field = params.fields{i};
			stat.factor(i).vals = unique(vec);
		end

		if ismember('interaction', params.anovan_in)
			numev = length(params.fields)+1;
		else
			numev = length(params.fields);
		end

		p = NaN(numev, size(pattern,2), size(pattern,3), size(pattern,4));
		% do the anova
		fprintf('Channel: ');
		for c=1:size(pattern,2)
			fprintf('%s ', pat.dim.chan(c).label);
			for t=1:size(pattern,3)
				for f=1:size(pattern,4)
					p(:,c,t,f) = anovan(squeeze(pattern(:,c,t,f)), group, 'display', 'off', params.anovan_in{:});
				end
			end
		end
		fprintf('\n');

		save(stat.file, 'p');

		% update the exp struct
		exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat.name, 'stat', stat);
	end