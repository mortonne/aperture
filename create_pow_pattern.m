function eeg = create_pow_pattern(eeg, params, resDir, patname)
%eeg = create_pow_pattern(eeg, params, resDir, patname)
%
% create a power pattern for each subject, time bin, saved in
% resDir/data.  Filenames will be saved in eeg.subj(s).pat
% with the patname specified.
% 

if ~exist('patname', 'var')
  patname = 'power_pattern';
end

% set the defaults for params
params = structDefaults(params,  'eventFilter', '',  'freqs', 2.^(1:(1/8):6),  'offsetMS', -200,  'durationMS', 1800,  'binSizeMS', 100,  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 200,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'resampledRate', 500,  'width', 6,  'kthresh', 5,  'ztransform', 1,  'logtransform', 0,  'replace_eegFile', {});

% get bin information
durationSamp = fix(params.durationMS*params.resampledRate./1000);
binSizeSamp = fix(params.binSizeMS*params.resampledRate./1000);
nBins = fix(durationSamp/binSizeSamp);

% prepare time and frequency bins
binSamp{1} = [1:binSizeSamp];
for b=2:nBins
  binSamp{b} = binSamp{b-1} + binSizeSamp;
end
for b=1:length(binSamp)
  params.binMS{b} = fix((binSamp{b}-1)*1000/params.resampledRate) + params.offsetMS;
end

for f=1:length(params.freqs)
  params.binFreq{f} = params.freqs(f);
end

disp(params);

rand('twister',sum(100*clock));

% prepare dir for the patterns
if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'))
end

% write all file info and update the eeg struct
for s=1:length(eeg.subj)
  pat.name = patname;
  pat.file = fullfile(resDir, 'data', [eeg.subj(s).id '_powpat.mat']);
  pat.eventsFile = fullfile(resDir, 'data', [eeg.subj(s).id '_events.mat']);
  pat.params = params;
  
  eeg.subj(s) = setobj(eeg.subj(s), 'pat', pat);
end
save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');

for s=1:length(eeg.subj)
  pat = getobj(eeg.subj(s), 'pat', patname);
  
  % see if this subject has been done
  if ~lockFile(pat.file)
    continue
  end
  
  % get all events for this subject, w/filter that will be used to get voltage
  events = [];
  base_events = [];
  for n=1:length(eeg.subj(s).sess)
    temp = loadEvents(eeg.subj(s).sess(n).eventsFile, params.replace_eegFile);
    events = [events; filterStruct(temp(:), params.eventFilter)];
    base_events = [base_events; filterStruct(temp(:), params.baseEventFilter)];
  end 
  sessions = unique(getStructField(events, 'session'));
  
  % check if using custom channels
  if isfield(params, 'channels')
    channels = params.channels;
  else
    channels = getStructField(eeg.subj(s).chan, 'number');
  end
  
  % initialize this subject's pattern
  patSize = [length(events), length(channels), length(params.binMS), length(params.binFreq)];
  pattern = NaN(patSize);
  
  % set up masks
  m = 1;
  mask(m).name = 'bad_channels';
  mask(m).mat = false(patSize);
  if ~isempty(params.kthresh)
    mask(m).name = 'kurtosis';
    mask(m).mat = false(patSize);
    m = m + 1;
  end
  if isfield(params, 'artWindow') && ~isempty(params.artWindow)
    mask(m).name = 'artifacts';
    mask(m).mat = false(patSize);

    for e=1:length(events)
      wind = [events(e).artifactMS events(e).artifactMS+params.artWindow];
      isArt = 0;
      for b=1:length(params.binMS)
	if wind(1)>params.binMS{b}(1) & wind(1)<params.binMS{b}(end)
	  isArt = 1;
	end
	mask(m).mat(e,:,b) = isArt;
	if isArt & wind(2)<params.binMS{b}(end)
	  isArt = 0;
	end
      end
    end
      
  end
  
  % get the patterns for each frequency and time bin
  start_e = 1;
  for n=1:length(eeg.subj(s).sess)
    fprintf('\n%s\n', eeg.subj(s).sess(n).eventsFile);
    this_sess = inStruct(events, 'session==varargin{1}', sessions(n));
    sess_events = events(this_sess);
    sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));
    
    % make bad channels mask
    bad = setdiff(channels, eeg.subj(s).sess(n).goodChans);
    mask(1).mat(this_sess, bad, :) = 1;
    
    for f=1:length(params.freqs)
      fprintf('\nLoading power values (%.2fHz)...', params.freqs(f));
      
      for c=1:length(channels)
	fprintf('%d.', channels(c));
	
	% get baseline stats for this freq, sess, channel
	if params.ztransform
	  base_pow = getphasepow(channels(c), sess_base_events, ...
	                             params.baseDurationMS, ...
			             params.baseOffsetMS, params.bufferMS, ... 
			             'freqs', params.freqs(f), ... 
				     'filtfreq', params.filtfreq, ... 
				     'filttype', params.filttype, ...
				     'filtorder', params.filtorder, ... 
				     'kthresh', params.kthresh, ...
				     'width', params.width, ...
                                     'resampledRate', params.resampledRate, ...
			             'powonly');
	  
	  if params.logtransform
	    base_pow(base_pow<=0) = eps(0);
	    base_pow = log10(base_pow);
	  end
	  
	  rand_pow = NaN(1,length(sess_events));
	  for e=1:size(base_pow,1)
	    randposs = randperm(size(base_pow,2));
	    rand_pow(e) = base_pow(e,randposs(1));
	  end
	  
	  base_mean = nanmean(rand_pow);
	  base_std = nanstd(rand_pow);	   
	end
	
	% get power, z-transform, average each time bin
	e = start_e;
	for sess_e=1:length(sess_events)
	  
	  [this_pow, kInd] = getphasepow(channels(c), sess_events(sess_e), ...
				   params.durationMS, ...
			             params.offsetMS, params.bufferMS, ... 
			             'freqs', params.freqs(f), ... 
				     'filtfreq', params.filtfreq, ... 
				     'filttype', params.filttype, ...
				     'filtorder', params.filtorder, ... 
				     'kthresh', params.kthresh, ...
				     'width', params.width, ...
                                     'resampledRate', params.resampledRate, ...
			             'powonly', 'keepk');   
	  
	  this_pow = squeeze(this_pow);
	  mask(1).mat(e,c,:,f) = kInd;
	  
	  if params.ztransform
	    if params.logtransform
	      this_pow(this_pow<=0) = eps(0);
	      this_pow = log10(this_pow);
	    end
	    this_pow = (this_pow - base_mean)/base_std;
	  end
	  
	  if ~isempty(this_pow)
	    for b=1:nBins
	      pattern(e,c,b,f) = nanmean(this_pow(binSamp{b}));
	    end
	  end
	  
	  e = e + 1;
	end % events
	
      end % channel
      
    end % freq
    start_e = start_e + length(events{n});
    
  end % session
  fprintf('\n');
  
  % save the patterns and masks
  save(pat.file, 'pattern', 'mask');
  releaseFile(pat.file);
  save(pat.eventsFile, 'events');
  
end % subj




