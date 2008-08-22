function [pat,eid] = modify_pats(pat, params, patname, resDir)
%MODIFY_PATS   Modify existing patterns.
%   PAT = MODIFY_PATS(PAT,PARAMS,PATNAME,RESDIR) modifies PAT using 
%   options in the PARAMS struct.  New patterns are saved in RESDIR/patterns.
%
%   See patFilt for options for filtering each dimension, and see patBins 
%   for binning each dimension.
%
%   See patPCA for options for getting principal components of patterns.
%
%   Also see applytosubj.
%

if ~exist('resDir','var')
  resDir = fullfile(fileparts(fileparts(fileparts(pat.file))),patname);
end
if ~exist('patname','var')
  patname = [pat.name '_mod'];
end
if ~exist('params','var')
  params = struct;
end

params = structDefaults(params, 'nComp',[], 'overwrite',0, 'lock',0);

oldpat = pat;

% initialize the new pat object
if ~strcmp(oldpat.name, patname)
  % if the patname is different, save the pattern to a new file
  patfile = fullfile(resDir, 'patterns', objfilename('pattern', patname, pat.source));
  else
  patfile = oldpat.file;
end

pat = init_pat(patname,patfile,oldpat.source,combineStructs(params,oldpat.params),oldpat.dim);
if isfield(oldpat,'stat')
  pat.stat = oldpat.stat;
end

% check input files and prepare output files
eid = prepFiles(oldpat.file, pat.file, params);
if eid
  return
end

% load the pattern
[pattern, events] = loadPat(oldpat, params);

% apply filters
[pat,inds,events,evmod(1)] = patFilt(pat,params,events);
pattern = pattern(inds{:});

% do binning
[pat,patbins,events,evmod(2)] = patBins(pat,params,events);
pattern = patMeans(pattern, patbins);

if ~isempty(params.nComp)
  % run PCA on the pattern
  [pat, pattern, coeff] = patPCA(pat, params, pattern);
  coeffFile = fullfile(resDir, 'patterns', objfilename('coeff', patname, pat.source));
  pat.dim.coeff = coeffFile;
  save(pat.dim.coeff, 'coeff');
end

fprintf('Pattern "%s" created.\n', pat.name)

if any(evmod)
  if ~exist(fullfile(resDir, 'events'), 'dir')
    mkdir(fullfile(resDir, 'events'));
  end

  % we need to save a new events struct
  pat.dim.ev.file = fullfile(resDir, 'events', objfilename('events', patname, pat.source));  
  save(pat.dim.ev.file, 'events');
end

% save the new pattern
save(pat.file, 'pattern');
closeFile(pat.file);
