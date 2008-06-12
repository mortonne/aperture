function zip_raw(exp, cmd)
%
%ZIP_RAW   Run bzip2 or bunzip2 on all rawfiles in an experiment.
%

for s=1:length(exp.subj)
	for n=1:length(exp.subj(s).sess)
		eegdir = fullfile(exp.subj(s).sess(n).dir, 'eeg');
		if strcmp(cmd, 'unzip')
			d = dir(fullfile(eegdir, '*raw.bz2'));
			if isempty(d)
				fprintf('%s empty.\n', eegdir)
				continue
			end
			filename = d.name;
			filename = strrep(filename, ' ', '\ ');
			%system(['ls ' fullfile(eegdir, filename)]);
			system(['bunzip2 ' fullfile(eegdir, filename)]);
		end
	end
end
