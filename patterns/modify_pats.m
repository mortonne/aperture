function pat = modify_pats(pat, params, patname, resDir)
%
%MODIFY_PATS   Modify existing patterns.
%   EXP = MODIFY_PATS(EXP,PARAMS,PATNAME,RESDIR) modifies the patterns
%   named PATNAME corresponding to each subject in EXP, using options
%   in the PARAMS struct.  New patterns are saved in RESDIR/patterns.
%
%   See eventBins, chanBins, timeBins, and freqBins for options for 
%   binning each dimension.
%
%   See patPCA for options for getting principal components of patterns.
%

[dir,filename] = fileparts(pat.file);

if ~exist('resDir','var')
  resDir = fullfile(fileparts(fileparts(dir)), patname);
end
if ~exist('patname','var')
  patname = [pat.name '_mod'];
end

params = structDefaults(params, 'eventFilter', '',  'nComp', []);

oldpatfile = pat.file;

if ~strcmp(pat.name, patname)
  % if the patname is different, save the pattern to a new file
  pat.name = patname;
  pat.file = fullfile(resDir, 'patterns', sprintf('%s_%s.mat', pat.source, patname));
end
pat.params = combineStructs(params, pat.params);

% check input files and prepare output files
if prepFiles(oldpatfile, pat.file, params)~=0
  pat = [];
  return
end

% load the pattern
[pattern, events] = loadPat(pat, params);

% apply filters
[pat,inds,events,evmod(1)] = patFilt(pat,params,events);
pattern = pattern(inds{:});

% do binning
[pat, patbins, events,evmod(2)] = patBins(pat, params, events);
pattern = patMeans(pattern, patbins);

if ~isempty(params.nComp)
  % run PCA on the pattern
  [pat, pattern, coeff] = patPCA(pat1, params, pattern);
  coeffFile = fullfile(resDir, 'patterns', [subj.id '_' patname '_coeff.mat']);
  pat.dim.coeff = coeffFile;
  save(pat.dim.coeff, 'coeff');
end

fprintf('Pattern "%s" created.\n', pat.name)

if any(evmod)
  if ~exist(fullfile(resDir, 'events'), 'dir')
    mkdir(fullfile(resDir, 'events'));
  end

  % we need to save a new events struct
  pat.dim.ev.file = fullfile(resDir, 'events', [subj.id '_' patname '_events.mat']);
  save(pat.dim.ev.file, 'events');
end

% save the new pattern
save(pat.file, 'pattern');
closeFile(pat.file);

%{
% remove artifacts
if ~isempty(params.artWindow)
  mask = markArtifacts(events, pat1.dim.time, params.artWindow);

  for c=1:size(pattern,2)
    for f=1:size(pattern,4)
      pattern(:,c,:,f) = mask;
    end
  end
end
%}
