function exp = create_volt_pattern(exp, params, patname, resDir)
%
%CREATE_VOLT_PATTERN Gets voltage values for a set of events for
%   each subject included in the exp struct.
%   exp = create_volt_pattern(exp, params, patname, resDir) creates
%   a voltage pattern for each subject in exp using options listed
%   in the params struct, saves filenames and details about the
%   pattern in a "pat" substruct of exp.subj named patname, and saves the
%   pattern in resDir.
%
%   optional params fields:
%      evname - string specifying name of the ev object to use
%         (default "events")
%      eventFilter - string to be passed into filterStruct;
%         specifies the events to be included in the pattern
%      offsetMS - time in milliseconds from the start of each event
%      durationMS - time window of the pattern will be
%         offsetMS:offsetMS+durationMS
%      baseEventFilter - filter to use for baseline events, if ztransform==1
%      baseOffsetMS
%      baseDurationMS
%      filttype
%      filtfreq
%      filtorder
%      bufferMS
%      resampledRate
%      kthresh
%      ztransform
%      replace_eegfile - used in loadEvents to run strrep on the
%         eegfile field of the events struct
%      
%   output:
%      exp - updated with pat objects added to exp.subj.pat;
%         pat.name - string identifier of the pat object
%         pat.file - filename of the saved pattern
%         pat.params - stores the params used to create the pattern
%         pat.dim - contains information about each dimension of the pattern
%
%      pattern - one for each subject s is saved in
%         exp.subj(s).pat.file.  Dimensions are events X channels X time.
%
fprintf('In create_volt_pattern');
if ~exist('params', 'var')
  params = struct();
end
if ~exist('patname', 'var')
  patname = 'volt_pattern';
end
if ~exist('resDir', 'var')
  resDir = fullfile(exp.resDir, patname);
end

% set the defaults for params
params = structDefaults(params,  'evname', 'events',  'eventFilter', '',  'chanFilter', '',  'resampledRate', 500,  'offsetMS', -200,  'durationMS', 1800,  'relativeMS', [],  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 100,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'kthresh', 5,  'artWindow', 500,  'ztransform', 1,  'replace_eegfile', {},  'lock', 1,  'overwrite', 0,  'doBinning', 0);

% get time bin information
stepSize = fix(1000/params.resampledRate);
MSvals = [params.offsetMS:stepSize:(params.offsetMS+params.durationMS-1)];
time = init_time(MSvals);

disp(params);

for s=1:length(exp.subj)
  % set where the pattern will be saved
  patfile = fullfile(resDir, 'patterns', ['pattern_' patname '_' exp.subj(s).id '.mat']);
  evfile = fullfile(resDir, 'events', ['events_' patname '_' exp.subj(s).id '.mat']);
  
  % get the ev object to be used for this pattern
  ev = getobj(exp.subj(s), 'ev', params.evname);
  
  % get all events for this subject, w/filter that will be used to get voltage
  events = loadEvents(ev.file, params.replace_eegfile);
  events = filterStruct(events, '~strcmp(eegfile, '''')');
  base_events = filterStruct(events(:), params.baseEventFilter);
  events = filterStruct(events(:), params.eventFilter);
  
  % change the ev object
  ev.file = evfile;
  ev.len = length(events);
  
  % save the events corresponding to this pattern
  save(ev.file, 'events');
  releaseFile(ev.file);
  
  % get chan, filter if desired
  chan = filterStruct(exp.subj(s).chan, params.chanFilter);
  
  % create a pat object to keep track of this pattern
  pat = init_pat(patname, patfile, params, ev, chan, time);

  % update exp with the new pat object
  exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);
  
  % check input files and prepare output files
  if prepFiles({}, {patfile, evfile}, params)~=0
    continue
  end
  
  % initialize this subject's pattern
  patSize = [pat.dim.ev.len, length(pat.dim.chan), length(pat.dim.time)];
  pattern = NaN(patSize);
  
  % initialize a boolean matrix to keep track of kurtosis
  kMask = false(patSize);

  % create a boolean matrix to keep track of artifacts
  mask = struct();
  if isfield(params, 'artWindow') && ~isempty(params.artWindow)
    artMask = false(patSize);
    timeArtMask = rmArtifacts(events, pat.dim.time, params.artWindow);
    for c=1:size(artMask,2)
      artMask(:,c,:) = timeArtMask;
    end
    mask = setobj(mask, struct('name', 'artifacts', 'mat', artMask));
  end

  % get a list of sessions in the filtered event struct
  sessions = unique(getStructField(events, 'session'));
  
  % make the pattern for this subject
  start_e = 1;
  for n=1:length(sessions)
    fprintf('\nProcessing %s session_%d:\n', exp.subj(s).id, sessions(n));
    sess_events = filterStruct(events, 'session==varargin{1}', sessions(n));
    sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));
    
    for c=1:length(chan)
      fprintf('%s.', chan(c).label);
      
      % get baseline stats for this channel, sess
      if params.ztransform
	base_eeg = gete_ms(chan(c).number, sess_base_events, ...
	                   params.baseDurationMS, ...
			   params.baseOffsetMS, params.bufferMS, ... 
			   params.filtfreq, params.filttype, ...
			   params.filtorder, params.resampledRate, ...
			   params.relativeMS);
	
	if ~isempty(params.kthresh)
	  base_eeg = run_kurtosis(base_eeg, params.kthresh);
	end

	% if multiple samples given, use the first
	base_eeg_vec = base_eeg(:,1);
	base_mean = nanmean(base_eeg_vec);
	base_std = nanstd(base_eeg_vec);   
      end
      
      % get power, z-transform, average each time bin
      e = start_e;
      for sess_e=1:length(sess_events)
	this_eeg = squeeze(gete_ms(chan(c).number, sess_events(sess_e), ...
	                   params.durationMS, params.offsetMS, ...
			   params.bufferMS, params.filtfreq, ...
			   params.filttype, params.filtorder, ...
			   params.resampledRate, params.relativeMS));
	
	% check kurtosis for this event, add info to boolean mask for later
	if ~isempty(params.kthresh)
	  kMask(e,c,:) = kurtosis(this_eeg)>params.kthresh;
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

  % put the masks in one struct
  mask = setobj(mask, struct('name', 'kurtosis', 'mat', kMask));
  
  if params.doBinning
    % do binning if desired
    [pat, pattern, events] = patBins(pat, pattern, events, mask);
    mask = struct();
  end
  
  % save the pattern and corresponding events struct and masks
  save(pat.file, 'pattern', 'mask');
  releaseFile(pat.file);
end % subj
