function exp = create_pattern(exp, fcnhandle, params, patname, resDir)
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
	patname = 'pattern';
end
if ~exist('resDir', 'var')
	resDir = fullfile(exp.resDir, patname);
end

% set the defaults for params
params = structDefaults(params,  'evname', 'events',  'replace_eegfile', {},  'eventFilter', '',  'baseEventFilter', '',  'chanFilter', '',  'resampledRate', 500,  'downsample', [],  'offsetMS', -200,  'durationMS', 1800,  'timeFilter', '',  'freqs', [],  'freqFilter', '',  'lock', 1,  'overwrite', 0,  'updateOnly', 0);

% get time bin information
if ~isempty(params.downsample)
	stepSize = fix(1000/params.downsample);
	else
	stepSize = fix(1000/params.resampledRate);
end
MSvals = [params.offsetMS:stepSize:(params.offsetMS+params.durationMS-1)];
time = init_time(MSvals);

% get frequency information
freq = init_freq(params.freqs);

fprintf('\nStarting create_pattern. Parameters are:\n\n')
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
	src_events = loadEvents(ev.file, params.replace_eegfile);
	base_events = filterStruct(src_events(:), params.baseEventFilter);

	% create a pat object to keep track of this pattern
	pat = init_pat(patname, patfile, params, ev, exp.subj(s).chan, time, freq);

	% do filtering/binning
	try
		[pat,inds,src_events,evmod(1)] = patFilt(pat,params,src_events);
		pat.params.channels = getStructField(pat.dim.chan, 'number');
		[pat,bins,events,evmod(2)] = patBins(pat,params,src_events);
		catch
		warning('Filtering/binning problem with %s.', exp.subj(s).id);
		continue
	end
	
	if any(evmod)
		% change the events name and file
		pat.dim.ev.name = sprintf('%s_mod', pat.dim.ev.name);
		pat.dim.ev.file = fullfile(resDir, 'events', sprintf('events_%s_%s.mat', patname, exp.subj(s).id));
		
		% save the modified event struct to a new file
		if ~exist(fileparts(pat.dim.ev.file), 'dir')
			mkdir(fileparts(pat.dim.ev.file));
		end
		save(pat.dim.ev.file, 'events');
	end

	% update exp with the new pat object
	exp = update_exp(exp, 'subj', exp.subj(s).id, 'pat', pat);

	if params.updateOnly
		continue
	end

	% initialize this subject's pattern
	pattern = NaN(length(src_events), length(pat.dim.chan), length(pat.dim.time), length(pat.dim.freq));

	% get a list of sessions in the filtered event struct
	sessions = unique(getStructField(src_events, 'session'));

	% CREATE THE PATTERN
	for n=1:length(sessions)
		fprintf('\nProcessing %s session %d:\n', exp.subj(s).id, sessions(n));
		sessInd = inStruct(src_events, 'session==varargin{1}', sessions(n));
		sess_events = src_events(sessInd);
		sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));

		% make the pattern for this session
		pattern(sessInd,:,:,:) = feval(fcnhandle, pat, bins, sess_events, sess_base_events);

	end % session
	fprintf('\n');

	% bin events
	pattern = patMeans(pattern, bins(1));

	% save the pattern
	save(pat.file, 'pattern');
	closeFile(pat.file);
end % subj
