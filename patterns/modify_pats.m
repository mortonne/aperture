function exp = modify_pats(exp, params, patname, resDir)
%
%MODIFY_PATS   Modify existing patterns.
%   EXP = MODIFY_PATS(EXP,PARAMS,PATNAME,RESDIR) modifies the patterns
%   named PATNAME corresponding to each subject in EXP, using options
%   in the PARAMS struct.  New patterns are saved in RESDIR/patterns.
%
%   See EVENTBINS, CHANBINS, TIMEBINS, and FREQBINS for options for 
%   binning each dimension.
%
%   See PATPCA for options for getting principal components of patterns.
%

if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, 'eeg', patname);
end

params = structDefaults(params, 'patname', '',  'eventFilter', '',  'masks', {},  'nComp', []);

if ~exist('patname', 'var')
  patname = [params.patname '_mod'];
end

% create the new pattern for each subject
for subj=exp.subj
  fprintf('\n%s\n', subj.id);
  
  % set where the pattern will be saved
  patfile = fullfile(resDir, 'patterns', [subj.id '_' patname '.mat']);
  
  % get the pat obj for the original pattern
  pat1 = getobj(subj, 'pat', params.patname);  
  
  % check input files and prepare output files
  if prepFiles(pat1.file, patfile, params)~=0
    continue
  end

	% load the pattern
	[pattern, events, evmod] = loadPat(pat1, params);
	
	if ~isempty(params.nComp)
		% run PCA on the pattern
		[pat, pattern, coeff] = patPCA(pat, params, pattern);
	end
	
	pat.name = patname;
  pat.file = patfile;
  pat.params = params;
  fprintf('Pattern "%s" created.\n', pat.name)
  
  if evmod
    if ~exist(fullfile(resDir, 'events'), 'dir')
      mkdir(fullfile(resDir, 'events'));
    end
    
    % we need to save a new events struct
    pat.dim.ev.file = fullfile(resDir, 'events', [subj.id '_' patname '_events.mat']);
    save(pat.dim.ev.file, 'events');
  end

  % update exp with the new pat object
  exp = update_exp(exp, 'subj', subj.id, 'pat', pat);
  
  % save the new pattern
	if exist('coeff','var')
		save(pat.file, 'pattern', 'coeff');
		else
  	save(pat.file, 'pattern');
	end
  closeFile(pat.file);
end % subj
