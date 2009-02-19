function [pat,pattern,events] = modify_pats(pat, params, patname, resDir)
%MODIFY_PAT   Modify an existing pattern.
%   PAT = MODIFY_PAT(PAT,PARAMS,PATNAME,RESDIR) modifies PAT using 
%   options in the PARAMS struct.  New patterns are saved in RESDIR/patterns.
%
%   See patFilt for options for filtering each dimension, and see patBins 
%   for binning each dimension.
%
%   See patPCA for options for getting principal components of patterns.
%
%   Also see applytosubj.

if isempty(pat)
  error('The input pat object is empty.')
end
if ~exist('patname','var') | isempty(patname)
  % default to overwriting the existing pattern
  patname = pat.name;
end
if ~exist('resDir','var')
  resDir = fullfile(fileparts(fileparts(fileparts(pat.file))),patname);
end
if ~exist('params','var')
  params = struct;
end

params = structDefaults(params, ...
                        'nComp',[], ...
                        'excludeBadChans',0, ...
                        'absThresh',[], ...
                        'overwrite',0, ...
                        'lock',0, ...
                        'savePat',1);

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
if prepFiles(oldpat.file, pat.file, params); % non-zero means error
  error('i/o problem.')
end

% load the pattern
[pattern, events] = loadPat(oldpat, params);

% apply filters
[pat,inds,events,evmod(1)] = patFilt(pat,params,events);
pattern = pattern(inds{:});

% ARTIFACT FILTERS
if params.excludeBadChans
  % load bad channel info
  [bad_chans, event_ind] = get_bad_chans({events.eegfile});
  
  % get current channel numbers
  chan_numbers = [pat.dim.chan.number];
  
  % combine channel and event info to make a bad channels logical array
  isbad = mark_bad_chans(chan_numbers, bad_chans, event_ind);

  % expand isbad to the same dimensions as pattern
  patsize = size(pattern);
  isbad = repmat(isbad, [1 1 patsize(3:end)]);
  
  % mark bad parts of the pattern
  pattern(isbad) = NaN;
end

if params.absThresh
  % find any values that are above our absolute threshold
  bad_samples = abs(pattern)>params.absThresh;
  
  % get a logical indicating events that have at least one bad sample
  pat_size = size(pattern);  
  bad_events = any(reshape(bad_samples, pat_size(1), prod(pat_size(2:end))), 2);
  
  % mark the bad events
  pattern(bad_events,:,:,:) = NaN;
  
  fprintf('Threw out %d events out of %d with abs. val. greater than %d.\n', sum(bad_events),length(events),params.absThresh)
end

% BINNING
[pat,patbins,events,evmod(2)] = patBins(pat,params,events);
pattern = patMeans(pattern, patbins);

% PCA
if ~isempty(params.nComp)
  % run PCA on the pattern
  [pat, pattern, coeff] = patPCA(pat, params, pattern);
  coeffFile = fullfile(resDir, 'patterns', objfilename('coeff', patname, pat.source));
  pat.dim.coeff = coeffFile;
  save(pat.dim.coeff, 'coeff');
end

fprintf('Pattern "%s" created.\n', pat.name)

if params.savePat
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
end
