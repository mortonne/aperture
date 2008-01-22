function eeg = increase_bin_size(eeg, params, resDir, patname)
%
%INCREASE_BIN_SIZE - average over adjacent time or frequency bins
%to decrease the size of patterns, or average over channels for ROI
%analyses; new patterns will be saved in a new directory
%
% FUNCTION: eeg = increase_bin_size(eeg, params, resDir, ananame)
%
% INPUT: eeg - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the eeg struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern)
%        resDir - 'pattern' files are saved in resDir/data
%        patname - name of new pattern to save under in the eeg struct
%
% OUTPUT: new eeg struct with ana object added, which contains file
% info and parameters of the analysis
%

%eeg = increase_bin_size(eeg, params, resDir, patname)
%
%EXAMPLES: params.binChan = {'LF', 'RF'} OR {{'LF', 'LFp'}, {'RF',
%'RFp'}} OR {[1 2 125], [45 35 76 17 18]}
%          params.MSbins = [0 100; 100 200]
%          params.freqbins = [2 4; 4 8]
%

if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end
if ~exist('patname', 'var')
  patname = [params.patname '_mod'];
end

params = structDefaults(params, 'eventFilter', '',  'masks', {});

if ~exist(fullfile(resDir, 'data'), 'dir');
  mkdir(fullfile(resDir, 'data'));
end 

pat1 = getobj(eeg.subj(1), 'pat', params.patname);

% make the new time bins (if applicable)
if isfield(params, 'MSbins') && ~isempty(params.MSbins)
  for t=1:length(params.MSbins)
    bint{t} = find(inStruct(pat1.dim.time, 'avg>=varargin{1} & avg<varargin{2}', params.MSbins(t,1), params.MSbins(t,2)));
    
    % get ms value for each sample in the new time bin
    allvals = [];
    for i=1:length(bint{t})
      allvals = [allvals pat1.dim.time(bint{t}(i)).MSvals];
    end    
    time(t).MSvals = allvals;
    time(t).avg = mean(allvals);
  end

else % time dim doesn't change
  for t=1:length(pat1.params.binMS)
    bint{t} = t;
  end
  time = pat1.dim.time;
end

% make the new frequency bins (if applicable)
if isfield(params, 'freqbins') && ~isempty(params.freqbins)
  for f=1:length(params.freqbins)
    binf{f} = find(inStruct(pat1.dim.freq, 'avg>=varargin{1} & avg<varargin{2}', params.freqbins(f,1), params.freqbins(f,2)));
    
    allvals = [];
    for i=1:length(binf{f})
      allvals = [allvals pat1.dim.freq(binf{f}(i)).vals];
    end    
    freq(f).vals = allvals;
    freq(f).avg = mean(allvals);
  end
  
elseif isfield(pat1.dim, 'freq') && ~isempty(pat1.dim.freq)
  for f=1:length(pat1.params.binFreq)
    binf{f} = f;
  end
  freq = pat1.dim.freq;
  
else % there is no frequency dimension
  binf{1} = 1;
  freq = [];
end

% write all file info and update the eeg struct
for s=1:length(eeg.subj)
  pat1 = getobj(eeg.subj(s), 'pat', params.patname);
  
  pat2.name = patname;
  pat2.file = fullfile(resDir, 'data', [eeg.subj(s).id '_' patname '.mat']);
  pat2.params = params;
  
  event.num = pat1.dim.event.num;
  event.file = fullfile(resDir, 'data', [eeg.subj(s).id '_' patname '_events.mat']);
  pat2.dim = struct('event', event, 'chan', chan, 'time', time, 'freq', freq);
  
  eeg.subj(s) = setobj(eeg.subj(s), 'pat', pat2);
end
save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');

keyboard
% make the new patterns
for s=1:length(eeg.subj)
  pat1 = getobj(eeg.subj(s), 'pat', params.patname);
  pat2 = getobj(eeg.subj(s), 'pat', patname);
  fprintf('%s\n', eeg.subj(s).id);

  if ~lockFile(pat2.file) | ~exist(pat1.file, 'file') | exist([pat1.file '.lock'], 'file')
    continue
  end
  
  % check if using custom channels
  if isfield(pat1.params, 'channels')
    eeg.subj(s).chan = filterStruct(eeg.subj(s).chan, 'ismember(number, varargin{1})', pat1.params.channels);
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
  
  pattern1 = loadPat(pat1.file, params.masks, .eventsFile, params.eventFilter);
  
  % initalize the new pat
  pattern2 = NaN(size(oldpat.mat,1), length(binc), length(binb), length(binf));
  
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