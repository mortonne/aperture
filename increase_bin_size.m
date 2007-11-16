function eeg = increase_bin_size(eeg, params, resDir, patname)
%eeg = increase_bin_size(eeg, params, resDir, patname)
%
%EXAMPLES: params.binChan = {'LF', 'RF'} OR {{'LF', 'LFp'}, {'RF',
%'RFp'}} OR {[1 2 125], [45 35 76 17 18]}
%          params.MSbins = [0 100; 100 200]
%          params.freqbins = [2 4; 4 8]
%

if ~exist('patname', 'var')
  patname = [params.pat '_mod'];
end

params = structDefaults(params,  'masks', {},  'eventFilter', '');

old = filterStruct(eeg.subj(1).pat, 'strcmp(name, varargin{1})', params.pat);
oldparams = old.params;

% make the new time bins (if applicable)
if isfield(params, 'MSbins')
  for i=1:length(oldparams.binMS)
    MSvals(i,1) = oldparams.binMS{i}(1);
    MSvals(i,2) = oldparams.binMS{i}(end);
  end
  for b=1:length(MSbins)
    binb{b} = find(MSvals(:,1)>=MSbins(b,1) & MSvals(:,2)<MSbins(b,2));
    % get ms value for each sample in the new time bin
    allvals = [];
    for j=1:length(binb{b})
      allvals = [allvals oldparams.binMS{binb{b}(j)}];
    end    
    params.binMS{b} = allvals;
  end

else % time dim doesn't change
  for b=1:length(oldparams.binMS)
    binb{b} = b;
  end
  params.binMS = oldparams.binMS;
end

% make the new frequency bins (if applicable)
if isfield(params, 'freqbins')
  freqs = oldparams.freqs;
  for f=1:length(params.freqbins)
    binf{f} = find(freqs>=freqbins(f,1) & freqs<freqbins(f,2));
    params.binFreq{f} = freqs(binf{f});
  end
  
elseif isfield(oldparams, 'binFreq') % frequency dim doesn't change
  for f=1:length(oldparams.binFreq)
    binf{f} = f;
  end
  params.binFreq = oldparams.binFreq;
  
else % there is no frequency dimension
  binf{1} = 1;
end

% prepare the results directory
if ~exist(fullfile(resDir, 'data'), 'dir');
  mkdir(fullfile(resDir, 'data'));
end    

% write all file info and update the eeg struct
for s=1:length(eeg.subj)
  old(s) = filterStruct(eeg.subj(s).pat, 'strcmp(name, varargin{1})', params.pat);
  
  new(s).name = patname;
  new(s).file = fullfile(resDir, 'data', [eeg.subj(s).id '_' patname '.mat']);
  new(s).eventsFile = old.eventsFile;
  new(s).params = params;
  
  p = length(eeg.subj(s).pat) + 1;

  eeg.subj(s).pat(p) = new(s);
end
save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');

% make the new patterns
for s=1:length(eeg.subj)
  fprintf('%s\n', eeg.subj(s).id);

  if ~lockFile(new(s).file) | isempty(old(s).file) | exist([old(s).file '.lock'], 'file')
    continue
  end
  
  % check if using custom channels
  if isfield(old(s).params, 'channels')
    eeg.subj(s).chan = filterStruct(eeg.subj(s).chan, 'ismember(number, varargin{1})', old(s).params.channels);
  end
  
  if isfield(params, 'binChan')
    channels = getStructField(eeg.subj(s).chan, 'number');
    regions = getStructField(eeg.subj(s).chan, 'region');
    
    for c=1:length(params.binChan)
      if isnumeric(binc{c})
	[vals, binc{c}] = intersect(channels, chanbins{c});
      else
	[vals, binc{c}] = intersect(regions, chanbins{c});	
      end
    end
  else % no averaging across channels
    for c=1:length(eeg.subj(s).chan)
      binc{c} = c;
    end  
  end
  
  oldpat = loadPat(old(s).file, params.masks, new(s).eventsFile, params.eventFilter);
  
  % initalize the new pat
  pat.id = oldpat.id;
  pat.mat = NaN(size(oldpat.mat,1), length(binc), length(binb), length(binf));
  
  for f=1:length(binf)
    fmean = nanmean(oldpat.mat(:,:,:,binf{f}),4);
    for b=1:length(binb)
      fprintf('%d.', b);
      bmean = nanmean(fmean(:,:,binb{b}),3);
      for c=1:length(binc)
	pat.mat(:,c,b,f) = nanmean(bmean(:,binc{c}),2);
      end
    end
  end
  fprintf('\n');
  
  save(new(s).file, 'pat');
  releaseFile(new(s).file);
  
end % subj