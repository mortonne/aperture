function eeg = increase_bin_size(eeg, resDir, masks, MSbins, freqbins)
%eeg = increase_bin_size(eeg, resDir, masks, MSbins, freqbins)

if nargin<5
  if isfield(eeg.params, 'binFreq')
    for f=1:length(eeg.params.binFreq)
      freqbins(f,1) = eeg.params.binFreq{f}(1);
      freqbins(f,2) = eeg.params.binFreq{f}(end);
    end
  else
    freqbins = [];
    binf{1} = 1;
  end
  if nargin<4
    for b=1:length(eeg.params.binMS)
      MSbins(b,1) = eeg.params.binMS{b}(1);
      MSbins(b,2) = eeg.params.binMS{b}(end);
    end
    if nargin<3
      masks = {};
    end
  end
end

params = eeg.params;
eeg.resDir = resDir;

% bin the time bins
eeg.params.binMS = cell(1,size(MSbins,1));
for i=1:length(params.binMS)
  MSvals(i) = squeeze(params.binMS{i}(1));
end
for b=1:length(MSbins)
  binb{b} = find(MSvals>=MSbins(b,1) & MSvals<MSbins(b,end));
  allvals = [];
  for i=1:length(binb{b})
    allvals = [allvals params.binMS{binb{b}}];
  end
  eeg.params.binMS{b} = unique(sort(allvals(:)));
end

if isfield(eeg.params, 'binFreq')
  eeg.params.binFreq = cell(1,size(freqbins,1));
  % bin the frequency bins
  for i=1:length(params.binFreq)
    freqvals(i) = squeeze(params.binFreq{i}(1));
  end
  for f=1:length(freqbins)
    if freqbins(f,1)==freqbins(f,2)
      binf{f} = find(freqvals==freqbins(f,1));
    else
      binf{f} = find(freqvals>=freqbins(f,1) & freqvals<freqbins(f,end));
    end
    allvals = [];
    for i=1:length(binf{f})
      allvals = [allvals params.binFreq{binf{f}}];
    end
    eeg.params.binFreq{f} = unique(sort(allvals(:)));
  end
end

% prepare the results directory
if ~exist(fullfile(resDir, 'data'), 'dir');
  mkdir(fullfile(resDir, 'data'));
end    

for s=1:length(eeg.subj)
  fprintf('%s\n', eeg.subj(s).id);
  
  oldPatFile = eeg.subj(s).patFile;
  
  if isempty(oldPatFile) | exist([oldPatFile '.lock'], 'file')
    continue
  end
  
  [p, fname] = fileparts(oldPatFile);
  eeg.subj(s).patFile = fullfile(eeg.resDir, 'data', [fname '.mat']);
  
  if ~lockFile(eeg.subj(s).patFile)
    save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
    continue
  end
  
  pat = loadPat(oldPatFile, masks);
  
  % initalize the new pat
  newpat.name = pat.name;
  newpat.mat = NaN(size(pat.mat,1), size(pat.mat,2), length(binb), length(binf));

  for f=1:length(binf)
    for b=1:length(binb)
      fprintf('%d.', b);
      fmean = squeeze(nanmean(pat.mat(:,:,:,binf{f}),4));
      newpat.mat(:,:,b,f) = squeeze(nanmean(fmean(:,:,binb{b}),3));  
    end
  end
  fprintf('\n');
  pat = newpat;
  
  % the masks for this pattern no longer apply
  save(eeg.subj(s).patFile, 'pat');
  releaseFile(eeg.subj(s).patFile);
  save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');
  
end % subj