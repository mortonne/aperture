function exp = create_volt_pattern(exp, params, patname, resDir)
%
%CREATE_VOLT_PATTERN Gets voltage values for a set of events for
%   each subject included in the exp struct.
%   exp                                                                   = create_volt_pattern(exp, params, patname, resDir) creates
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
%      baseEventFilter - filter to use for baseline events, if ztransform = =1
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
params = structDefaults(params,  'evname', 'events',  'eventFilter', '',  'chanFilter', '',  'resampledRate', 500,  'offsetMS', -200,  'durationMS', 1800,  'relativeMS', [],  'baseEventFilter', '',  'baseOffsetMS', -200,  'baseDurationMS', 100,  'filttype', 'stop',  'filtfreq', [58 62],  'filtorder', 4,  'bufferMS', 1000,  'kthresh', 5,  'artWindow', 500,  'ztransform', 1,  'replace_eegfile', {},  'lock', 1,  'overwrite', 0,  'doBinning', 0,  'updateOnly', 0);

% get time bin information
stepSize = fix(1000/params.resampledRate);
MSvals = [params.offsetMS:stepSize:(params.offsetMS+params.durationMS-1)];
time = init_time(MSvals);

% get frequency information
freq = init_freq(params.freqs);

fprintf('\nStarting create_volt_pattern. Parameters are:\n\n')
disp(params);

for s=1:length(exp.subj)
	% set where the pattern will be saved
	patfile = fullfile(resDir, 'patterns', sprintf('pattern_%s_%s.mat', patname, exp.subj(s).id));

	% check input files and prepare output files
	if prepFiles({}, patfile, params)~=0
		continue
	end

	% get this subject's events
	ev = getobj(exp.subj(s), 'ev', params.evname);
	events = loadEvents(ev.file, params.replace_eegfile);
	base_events = filterStruct(events(:), params.baseEventFilter);

	% get info about this subject's channels
	chan = exp.subj(s).chan;

	% create a pat object to keep track of this pattern
	pat = init_pat(patname, patfile, params, ev, chan, time);

	% do filtering/binning
	[pat,inds,events,evmod(1)] = patFilt(pat,params,events);
	[pat,bins,events,evmod(2)] = patBins(pat,params,events);

	if any(evmod)
		% change the ev object
		ev.file = fullfile(resDir, 'events', sprintf('events_%s_%s.mat', patname, exp.subj(s).id));
		ev.len = length(events);

		% save the modified event struct to a new file
		if ~exist(fileparts(ev.file), 'dir')
			mkdir(fileparts(ev.file));
		end
		save(ev.file, 'events');
	end

	% update exp with the new pat object
	exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);

	if params.updateOnly
		continue
	end

	% initialize this subject's pattern
	patSize = [pat.dim.ev.len, length(pat.dim.chan), length(pat.dim.time), length(pat.dim.freq)];
	pattern = NaN(patSize);

	% get a list of sessions in the filtered event struct
	sessions = unique(getStructField(events, 'session'));

	% CREATE THE PATTERN
	for n=1:length(sessions)
		fprintf('\nProcessing %s session %d:\n', exp.subj(s).id, sessions(n));
		sessInd = inStruct(events, 'session==varargin{1}', sessions(n));
		sess_events = events(sessInd);
		sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));

		% make the pattern for this session
		pattern(sessInd,:,:,:) = feval(fcnhandle, pat, sess_events, sess_base_events);

	end % session
	fprintf('\n');

	% bin events and channels
	pattern = patMeans(pattern, bins(1:2));

	% save the pattern
	save(pat.file, 'pattern');
	closeFile(pat.file);
end % subj
