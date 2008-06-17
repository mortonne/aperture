function exp = backup_exp(exp,bkdir)
%
%BACKUP_EXP   Make a timestamped backup of the exp struct.
%   EXP = BACKUP_EXP(EXP) saves a copy of exp in 
%   exp.resDir/exp_bk/exp_TIMESTAMP.mat.  The returned EXP has
%   the "lastUpdate" field set to TIMESTAMP.
%
%   EXP = BACKUP_EXP(EXP,BKDIR) saves the timestamped file in BKDIR.
%

% prepare the backup directory
if ~exist('bkdir','var')
	bkdir = fullfile(exp.resDir, 'exp_bk');
end
if ~exist(bkdir,'dir')
	mkdir(bkdir);
end

% write the filename
timestamp = datestr(now, 'ddmmmyy_HHMM');
bk_file = fullfile(bkdir, ['exp_' timestamp '.mat']);

% save
save(bk_file, 'exp');

% add last update time to the active exp
exp.lastUpdate = timestamp;
