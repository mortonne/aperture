function exp = create_volt_pattern(exp, params, resDir, patname)
% exp = create_volt_pattern(exp, params, resDir, patname)
%
% create a voltage pattern for each subject, time bin, saved in
% resDir/data.  Filenames will be saved in exp.subj(s).pat
% with the patname specified.
% 

if ~exist('patname', 'var')
  patname = 'voltage_pattern';
end

% set the defaults for params
params = structDefaults(params,  'evname', 'events',  'eventFilter', '',  'offsetMS', -200,  'durationMS', 1800,  'binSizeMS', 10,  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 200,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'resampledRate', 500,  'kthresh', 5,  'ztransform', 1,  'replace_eegfile', {},  'timebinlabels', {});

% get bin information
durationSamp = fix(params.durationMS*params.resampledRate./1000);
binSizeSamp = fix(params.binSizeMS*params.resampledRate./1000);
nBins = fix(durationSamp/binSizeSamp);

binSamp{1} = [1:binSizeSamp];
for b=2:nBins
  binSamp{b} = binSamp{b-1} + binSizeSamp;
end

for t=1:length(binSamp)
  time(t).MSvals = fix((binSamp{t}-1)*1000/params.resampledRate) + params.offsetMS;
  time(t).avg = mean(time(t).MSvals);
  if ~isempty(params.timebinlabels)
    time(t).label = params.timebinlabels{t};
  else
    time(t).label = [num2str(time(t).MSvals(1)) ' to ' num2str(time(t).MSvals(end)) 'ms'];
  end
end

disp(params);

rand('twister',sum(100*clock));

% prepare dir for the patterns
if ~exist(fullfile(resDir, 'data'), 'dir')
  mkdir(fullfile(resDir, 'data'));
end

% write all file info and update the exp struct
for s=1:length(exp.subj)
  pat.name = patname;
  pat.file = fullfile(resDir, 'data', [patname '_' exp.subj(s).id '.mat']);
  pat.params = params;
  
  % manage the dimensions info
  pat.dim = struct('event', [],  'chan', [],  'time', [],  'freq', []);
  
  pat.dim.event.num = [];
  pat.dim.event.file = fullfile(resDir, 'data', [patname '_' exp.subj(s).id '_events.mat']);
  
  if isfield(params, 'channels')
    pat.dim.chan = filterStruct(exp.subj(s).chan, 'ismember(number, varargin{1})', params.channels);
  else
    pat.dim.chan = exp.subj(s).chan;
  end
  pat.dim.time = time;

  % add new pat object to the exp struct
  exp.subj(s) = setobj(exp.subj(s), 'pat', pat);
end
save(exp.file, 'exp');

for s=1:length(exp.subj)
  pat = getobj(exp.subj(s), 'pat', patname);
  
  % see if this subject has been done
  %if ~lockFile(pat.file)
  %  continue
  %end
  
  % get all events for this subject, w/filter that will be used to get voltage
  ev = getobj(exp.subj(s), 'ev', params.evname);
  events = loadEvents(ev.file, params.replace_eegfile);
  events = filterStruct(events, '~strcmp(eegfile, '''')');
  base_events = filterStruct(events(:), params.baseEventFilter);
  events = filterStruct(events(:), params.eventFilter);

  % get some stats
  pat.dim.event.num = length(events);
  sessions = unique(getStructField(events, 'session'));
  channels = getStructField(pat.dim.chan, 'number');
  
  % initialize this subject's pattern
  patSize = [pat.dim.event.num, length(pat.dim.chan), length(pat.dim.time)];
  pattern = NaN(patSize);
  
  % set up masks
  m = 1;
  mask(m).name = 'bad_channels';
  mask(m).mat = false(patSize);
  m = m + 1;
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
      for t=1:length(time)
	if wind(1)>time(t).MSvals(1) & wind(1)<time(t).MSvals(end)
	  isArt = 1;
	end
	mask(m).mat(e,:,t) = isArt;
	if isArt & wind(2)<time(t).MSvals(end)
	  isArt = 0;
	end
      end
    end
    
  end
  
  % make the pattern for this subject
  start_e = 1;
  for n=1:length(sessions)
    fprintf('\n%s\n', exp.subj(s).sess(n).eventsFile);
    this_sess = inStruct(events, 'session==varargin{1}', sessions(n));
    sess_events = events(this_sess);
    sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));
    
    % make bad channels mask
    bad = setdiff(channels, exp.subj(s).sess(n).goodChans);
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
  %releaseFile(pat.file);
  save(pat.dim.event.file, 'events');
  
  % add event info to pat, so save exp again
  load(exp.file);
  exp.subj(s) = setobj(exp.subj(s), 'pat', pat);
  save(exp.file, 'exp');
end % subj
