function exp = update_exp(exp, varargin)
	%exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);

	lock = 0;

	fprintf('In update_exp: ');
	
	if lock
		if ~lockFile(exp.file, 1);
			error('Locking timed out.')
		end
		fprintf('Locked...');
	end

	% get the latest version of exp
	load(exp.file);
	fprintf('Loaded...')

	% make a backup of exp with a timestamp
	bk_dir = fullfile(exp.resDir, 'exp_bk');
	if ~exist(bk_dir)
		mkdir(bk_dir);
	end
	timestamp = datestr(now, 'ddmmmyy_HHMM');
	bk_file = fullfile(bk_dir, ['exp_' timestamp '.mat']);
	save(bk_file, 'exp');

	if length(varargin)>0
		% add the object in place specified
		exp = recursive_setobj(exp, varargin);
	end

	save(exp.file, 'exp');

	if lock
		releaseFile(exp.file);
	end
	
	fprintf('Updated and saved.\n');
