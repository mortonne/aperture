function exp = grand_average(exp, patname, resDir)
%
%GRAND AVERAGE   Calculate an average across patterns from multiple subjects.
%   EXP = GRAND_AVERAGE(EXP,PATNAME,RESDIR)
%
%   This script assumes that the dimensions of all subjects' patterns
%   are identical.
%

if ~exist('resDir', 'var')
	resDir = fullfile(exp.resDir, 'eeg', patname);
end

subjpat = getobj(exp.subj(1), 'pat', patname);

% initialize the new pattern
patfile = fullfile(resDir, 'patterns', [patname '_ga.mat']);
pat = init_pat(patname, patfile);
pat.dim = subjpat.dim;

% get filenames for all subject patterns
for s=1:length(exp.subj)
	subjpat = getobj(exp.subj(s), 'pat', patname);
	subjfiles{s} = subjpat.file;
end

% check input files, lock output if desired
if prepFiles(subjfiles, pat.file)~=0
	error('Problem with one of the input files.')
end

% initialize pattern to hold all subjects
pattern = NaN(pat.dim.ev.len, length(pat.dim.chan), length(pat.dim.time), length(pat.dim.freq), length(exp.subj));

% get all subjects' means
for s=1:length(subjfiles)
	subj_pattern = loadPat(subjfiles{s});
	pattern(:,:,:,:,s) = subj_pattern;
end

% average across subjects
pattern = mean(pattern,5);
save(pat.file, 'pattern');
closeFile(pat.file);

% add the new grand average pat object to the exp struct
exp = update_exp(exp, 'pat', pat);
