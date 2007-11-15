function eeg = create_volt_pattern(eeg, params, patname, resDir)
% eeg = create_volt_pattern(eeg, resDir)
%
% create a voltage pattern for each subject, time bin
% 

% set the defaults for params
params = structDefaults(params,  'eventFilter', '',  'offsetMS', -200,  'durationMS', 1800,  'binSizeMS', 10,  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 200,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'resampledRate', 500,  'kthresh', 5,  'ztransform', 1,  'replace_eegFile', {});

% get bin information
durationSamp = fix(params.durationMS*params.resampledRate./1000);
binSizeSamp = fix(params.binSizeMS*params.resampledRate./1000);
nBins = fix(durationSamp/binSizeSamp);

binSamp{1} = [1:binSizeSamp];
for b=2:nBins
  binSamp{b} = binSamp{b-1} + binSizeSamp;
end

% get MS values
for b=1:length(binSamp)
  params.binMS{b} = fix((binSamp{b}-1)*1000/params.resampledRate) + params.offsetMS;
end

disp(params);

% prepare dir for the patterns
if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

% write all file info and save eeg struct
for s=1:length(eeg.subj)
  p = length(eeg.subj(s).pat) + 1;
  
  eeg.subj(s).pat(p).name = patname;
  eeg.subj(s).pat(p).file = fullfile(resDir, 'data', [eeg.subj(s).id '_voltpat.mat']);
  eeg.subj(s).pat(p).params = params;
  eeg.subj(s).pat(p).eventsFile = fullfile(resDir, 'data', [eeg.subj(s).id '_events.mat']);
end
save(fullfile(eeg.resDir, 'eeg.mat'), eeg);

for s=1:length(eeg.subj)
  
  % see if this subject has been done
  if ~lockFile(eeg.subj(s).pat(p).file)
    continue
  end
  
  % get all events for this subject, w/filter that will be used to get voltage
  events = [];
  base_events = [];
  for n=1:length(eeg.subj(s).sess)
    temp = loadEvents(eeg.subj(s).sess(n).eventsFile, params.replace_eegFile);
    events = [events; filterStruct(temp, params.eventFilter)];
    base_events = [base_events; filterStruct(temp, params.baseEventFilter)];
  end 
  session = getStructField(events, 'session');
  
  % check if using custom channels
  if isfield(params, 'channels')
    channels = params.channels;
  else
    channels = getStructField(eeg.subj(s).chan, 'number');
  end
  
  % initialize this subject's pattern
  patSize = [nEvents, length(channels), length(params.binMS)];
  pat.name = eeg.subj(s).id;
  pat.mat = NaN(patSize);
  
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
    m = m + 1;
  end
  
  % make bad channels mask
  for n=1:length(eeg.subj(s).sess)
    bad = setdiff(channels, eeg.subj(s).sess(n).goodChans);
    mask(2).mat(e,bad,session==eeg.subj(s).sess(n).number) = 1;
  end

  % blink artifacts
  for e=1:length(events)
    
    if isfield(params, 'artWindow') && ~isempty(params.artWindow)
      
      wind = [events(e).artifactMS events(e).artifactMS+params.artWindow];
      isArt = 0;
      for b=1:length(params.binMS)
	if wind(1)>params.binMS{b}(1) & wind(1)<params.binMS{b}(end)
	  isArt = 1;
	end
	mask(3).mat(e,:,b) = isArt;
	if isArt & wind(2)<params.binMS{b}(end)
	  isArt = 0;
	end
      end
      
    end
  end
    
  start_e = 1;
  for n=1:length(eeg.subj(s).sess)
    fprintf('\n%s\n', eeg.subj(s).sess(n).eventsFile);
    sess_events = events(session==eeg.subj(s).sess(n).number);
    sess_base_events = base_events(session==eeg.subj(s).sess(n).number);
    
    for c=1:length(channels)
      fprintf('%d.', channels(c));
      
      % get baseline stats for this channel, sess
      if params.ztransform
	base_eeg = gete_ms(channels(c), sess_base_events, ...
	                   params.baseDurationMS, ...
			   params.baseOffsetMS, params.bufferMS, ... 
			   params.filtfreq, params.filttype, ...
			   params.filtorder, params.resampledRate, ...
			   params.baseRelativeMS);
	
	if ~isempty(params.kthresh)
	  base_eeg = run_kurtosis(base_eeg, params.kthresh);
	end
	  
	poss = 1:size(base_eeg,2);
	for e=1:size(base_eeg,1)
	  randposs = randperm(length(poss));
	  rand_eeg(e) = base_eeg(e,randposs(1));
	end
	
	base_mean = nanmean(rand_eeg(:));
	base_std = nanstd(rand_eeg(:));	   
      end
      
      % get power, z-transform, average each time bin
      e = start_e;
      for sess_e=1:length(events{n})
	this_eeg = squeeze(gete_ms(channels(c), sess_events(sess_e), ...
	                   params.durationMS, params.offsetMS, ...
			   params.bufferMS, params.filtfreq, ...
			   params.filttype, params.filtorder, ...
			   params.resampledRate, params.relativeMS));
	
	if ~isempty(params.kthresh)
	  mask(2).mat(e,c,:) = kurtosis(this_eeg)>params.kthresh;
	end
	
	if params.ztransform
	  this_eeg = (this_eeg - base_mean)/base_std;
	end
	
	for b=1:nBins
	  pat.mat(e,c,b) = nanmean(this_eeg(binSamp{b}));
	end
	
	e = e + 1;
      end % events
      
    end % channel
    start_e = start_e + length(sess_events);
    
  end % session
  fprintf('\n');
  
  % save the patterns and corresponding events struct
  save(eeg.subj(s).pat(p).file, 'pat', 'mask');
  releaseFile(eeg.subj(s).pat(p).file);
  save(eeg.subj(s).pat(p).eventsFile, 'events');
  
end % subj
