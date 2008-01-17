function eeg = create_volt_pattern(eeg, params, resDir, patname)
% eeg = create_volt_pattern(eeg, params, resDir, patname)
%
% create a voltage pattern for each subject, time bin, saved in
% resDir/data.  Filenames will be saved in eeg.subj(s).pat
% with the patname specified.
% 

if ~exist('patname', 'var')
  patname = 'voltage_pattern';
end

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

for b=1:length(binSamp)
  params.binMS{b} = fix((binSamp{b}-1)*1000/params.resampledRate) + params.offsetMS;
end

disp(params);

rand('twister',sum(100*clock));

% prepare dir for the patterns
if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

% write all file info and update the eeg struct
for s=1:length(eeg.subj)
  pat.name = patname;
  pat.file = fullfile(resDir, 'data', [eeg.subj(s).id '_' patname '.mat']);
  pat.eventsFile = fullfile(resDir, 'data', [eeg.subj(s).id '_' patname '_events.mat']);
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
  patSize = [length(events), length(channels), length(params.binMS)];
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
  
  % make the pattern for this subject
  start_e = 1;
  for n=1:length(eeg.subj(s).sess)
    fprintf('\n%s\n', eeg.subj(s).sess(n).eventsFile);
    this_sess = inStruct(events, 'session==varargin{1}', sessions(n));
    sess_events = events(this_sess);
    sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));
    
    % make bad channels mask
    bad = setdiff(channels, eeg.subj(s).sess(n).goodChans);
    mask(1).mat(this_sess, bad, :) = 1;
    
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
	  
	rand_eeg = NaN(1,length(sess_events));
	for e=1:size(base_eeg,1)
	  randposs = randperm(size(base_eeg,2));
	  rand_eeg(e) = base_eeg(e,randposs(1));
	end
	
	base_mean = nanmean(rand_eeg);
	base_std = nanstd(rand_eeg);	   
      end
      
      % get power, z-transform, average each time bin
      e = start_e;
      for sess_e=1:length(sess_events)
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
	  pattern(e,c,b) = nanmean(this_eeg(binSamp{b}));
	end
	
	e = e + 1;
      end % events
      
    end % channel
    start_e = start_e + length(sess_events);
    
  end % session
  fprintf('\n');
  
  % save the patterns and corresponding events struct
  save(pat.file, 'pattern', 'mask');
  releaseFile(pat.file);
  save(pat.eventsFile, 'events');
  
end % subj
