function exp = update_exp(exp, varargin)
%
%UPDATE_EXP   Apply changes to the exp struct.
%   EXP = UPDATE_EXP(EXP) is the same as save(exp.file,'exp').
%
%   EXP = UPDATE_EXP(EXP,VARARGIN) loads the most recently
%   saved version of EXP (locking first if exp.useLock is true),
%   makes a backup of that version in exp.resDir/exp_bk,
%   runs RECURSIVE_SETOBJ to add an object to EXP, then saves
%   the modified version in exp.file.
%   
%   The last two arguments of VARARGIN should be an object type,
%   i.e. 'pat', and the object to be added.  If there are other
%   arguments of VARARGIN, they should be object type, object name
%   pairs that climb the exp heirarchy.
%
%   EXAMPLE:
%      exp = update_exp(exp,'subj','LTP001','pat',pat)
%      gets the subject named LTP001, then adds pat to that subject's
%      list of patterns.
%

fprintf('In update_exp: ');

if length(varargin)>0
	% need to first add an object to exp
	if ~isfield(exp, 'useLock')
		exp.useLock = 1;
	end
	
	% if running on the cluster, take possession of exp first
	if exp.useLock
		if ~lockFile(exp.file, 1);
			error('Locking timed out.')
		end
		fprintf('Locked...');
	end

	% get the latest version of exp
	load(exp.file);
	fprintf('Loaded...')

	% make a backup before making changes
	exp = backup_exp(exp);

	% add the object in place specified
	exp = recursive_setobj(exp, varargin);
end

% commit the new version of exp
save(exp.file, 'exp');
closeFile(exp.file);

fprintf('Updated and saved.\n');
