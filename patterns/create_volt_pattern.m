function exp = create_volt_pattern(exp, params, patname, resDir)
% exp = create_volt_pattern(exp, params, patname, resDir)
%
% create a voltage pattern for each subject, time bin, saved in
% resDir/data.  Filenames will be saved in exp.subj(s).pat
% with the patname specified.
% 

if ~exist('patname', 'var')
  patname = 'voltage_pattern';
end
if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, patname);
end

% set the defaults for params
params = structDefaults(params,  'evname', 'events',  'eventFilter', '',  'chanbins', {},  'MSbins', {},  'offsetMS', -200,  'durationMS', 1800,  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 200,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'resampledRate', 500,  'kthresh', 5,  'ztransform', 1,  'replace_eegfile', {},  'timebinlabels', {},  'lock', 1,  'overwrite', 0);

% get time bin information
stepSize = fix(1000/params.resampledRate);
MSvals = [params.offsetMS:stepSize:(params.offsetMS+params.durationMS)];
[time, bint] = timeBins(MSvals, params);

disp(params);

rand('twister',sum(100*clock));

for s=1:length(exp.subj)
  % set where the pattern will be saved
  patfile = fullfile(resDir, 'data', [patname '_' exp.subj(s).id '.mat']);
  
  % check input files and prepare output files
  if prepFiles({}, patfile, params)~=0
    continue
  end
  
  % get the ev object to be used for this pattern
  ev = getobj(exp.subj(s), 'ev', params.evname);
  
  % get all events for this subject, w/filter that will be used to get voltage
  events = loadEvents(ev.file, params.replace_eegfile);
  events = filterStruct(events, '~strcmp(eegfile, '''')');
  base_events = filterStruct(events(:), params.baseEventFilter);
  events = filterStruct(events(:), params.eventFilter);
  ev.length = length(events);
  
  % get chan, divide the channels into regions to be averaged over later
  [chan, binc, channels] = chanBins(exp.subj(s).chan, params);
  
  % create a pat object to keep track of this pattern
  pat = init_pat(patname, patfile, params, ev, chan, time);
  
  % update exp with the new pat object
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);

  % initialize this subject's pattern
  patSize = [pat.dim.ev.length, length(channels), length(MSvals)];
  pattern = NaN(patSize);
  
  % set up masks
  m = 1;
  if ~isempty(params.kthresh)
    mask(m).name = 'kurtosis';
    mask(m).mat = false(patSize);
    m = m + 1;
  end
  if isfield(params, 'artWindow') && ~isempty(params.artWindow)
    mask(m).name = 'artifacts';
    mask(m).mat = false(patSize);

    artMask = rmArtifacts(events, pat.dim.time, params.artWindow);
    for c=1:size(mask(m),2)
      mask(m).mat(:,c,:) = artMask;
    end
  end

  % get a list of sessions in the filtered event struct
  sessions = unique(getStructField(events, 'session'));
  
  % make the pattern for this subject
  start_e = 1;
  for n=1:length(sessions)
    fprintf('\nProcessing %s session_%d:\n', exp.subj(s), sessions(n));
    this_sess = inStruct(events, 'session==varargin{1}', sessions(n));
    sess_events = events(this_sess);
    sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));
    
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

	rand_eeg = base_eeg(:,1);
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
	
	% check kurtosis for this event, add info to boolean mask for later
	if ~isempty(params.kthresh)
	  mask(1).mat(e,c,:) = kurtosis(this_eeg)>params.kthresh;
	end
	
	% normalize across sessions
	if params.ztransform
	  this_eeg = (this_eeg - base_mean)/base_std;
	end
	
	pattern(e,c,:) = this_eeg;
	e = e + 1;
      end % events
      
    end % channel
    start_e = start_e + length(sess_events);
    
  end % session
  fprintf('\n');
  
  % apply masks
  if ~isempty(params.masks)
    mask = filterStruct(mask, 'ismember(name, varargin{1})', params.masks);
    for m=1:length(mask)
      pattern(mask(m).mat) = NaN;
    end
  end
  
  % do binning
  for e=1:length(bine)
    emean = nanmean(pattern(bine{e},:,:),1);
    for c=1:length(binc)
      cmean = nanmean(emean(:,binc{c},:),2);
      for t=1:length(bint)
	pattern(e,c,t) = nanmean(cmean(:,:,bint{t}),3);
      end
    end
  end
  
  % save the pattern and corresponding events struct and masks
  closeFile(pat.file, 'pattern', 'mask');
  save(pat.dim.event.file, 'events');
end % subj
