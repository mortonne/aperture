function exp = cat_pats(exp, params, patname, resDir)
%
%CAT_PATS   Concatenate patterns.
%   EXP = CAT_PATS(EXP,PARAMS,PATNAME,RESDIR)
%

if ~exist('resDir', 'var')
	resDir = fullfile(exp.resDir, 'eeg', patname);
end
if ~exist('params','var') || ~isfield(params, 'patnames')
	error('You must specify the names of which patterns to concatenate.');
end

params = structDefaults(params, 'eventFilter', '',  'masks', {},  'dimension', 1);

if ~exist('patname', 'var')
	patname = 'combined_patterns';
end

% create the new pattern for each subject
for subj=exp.subj
	fprintf('\n%s\n', subj.id);

	% set where the pattern will be saved
	patfile = fullfile(resDir, 'patterns', [subj.id '_' patname '.mat']);

	for i=1:length(params.patnames)
		% get the pat object for the original pattern
		pat1(i) = getobj(subj, 'pat', params.patnames{i});
	end

	% initialize a new pat object
	pat = init_pat(patname, patfile, params, pat1(1).dim);

	% check input files and prepare output files
	if prepFiles({pat1.file}, patfile, params)~=0
		continue
	end

	fprintf('Concatenating...')
	switch params.dimension
		case 1

		case 2
		% make meta-data for the concatenated dimension
		chan = [];
		for i=1:length(pat1)
			chan = [chan pat1(i).dim.chan];
		end

		pat.dim.chan = chan;

		% prepare the new pattern
		dim1 = pat1(1).dim;
		pattern = NaN(dim1.ev.len,length(chan),length(dim1.time),length(dim1.freq));

		start = 1;
		for i=1:length(pat1)
			pattern(:,start:start+length(pat1(i).dim.chan)-1,:,:) = loadPat(pat1(i),params,0);
			start = start + length(pat1(i).dim.chan);
		end

		case 3

		case 4
	end
	fprintf('Pattern %s created.\n', patname)

	% save the new pattern
	save(pat.file, 'pattern')
	closeFile(pat.file);

	% update exp with the new pat object
	exp = update_exp(exp, 'subj', subj.id, 'pat', pat);
end
