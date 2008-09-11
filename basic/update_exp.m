function exp = update_exp(exp, varargin)
%UPDATE_EXP   Apply changes to the exp struct.
%   EXP = UPDATE_EXP(EXP) loads the most recently saved version of
%   EXP (locking first if exp.useLock is true), makes a backup of 
%   that version in exp.resDir/exp_bk, then saves the current version
%   in exp.file.
%
%   EXP = UPDATE_EXP(EXP,VARARGIN) makes a backup, runs 
%   RECURSIVE_SETOBJ to add an object to the most recently saved 
%   version of exp, then saves the new exp.
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

% if running on the cluster, take possession of exp first
if ~isfield(exp, 'useLock')
  exp.useLock = 1;
end

if exp.useLock
  if ~lockFile(exp.file, 1);
    error('Locking timed out.')
  end
  fprintf('Locked...');
end

% store the version of exp that was passed in
current = exp;

if exist(exp.file,'file')
  % get the last version of exp
  load(exp.file);
  fprintf('Loaded...')

  % make a backup of the old version before making changes
  exp = backup_exp(exp);
  else
  % exp hasn't been saved in exp.file before
  if ~exist(exp.resDir,'dir')
    mkdir(exp.resDir)
  end
end

if length(varargin)>0
	% add the object in place specified
	exp = recursive_setobj(exp, varargin);

  else
  % just save out the exp that was passed in
  current.lastUpdate = exp.lastUpdate;
  exp = current;
end

% commit the new version of exp
save(exp.file, 'exp');
closeFile(exp.file);

fprintf('Updated and saved.\n');
