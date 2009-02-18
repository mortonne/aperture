function subj = create_pattern(subj, fcnhandle, params, patname, resDir)
%CREATE_PATTERN   Create a pattern for each subject in an exp struct.
%   EXP = CREATE_PATTERN(EXP,FCNHANDLE,PARAMS,PATNAME,RESDIR) creates
%   a pattern for each subject in EXP.  FCNHANDLE creates the pattern
%   for each session; it should take pat, bins, events for a session, 
%   baseline events for the session, and output a pattern with
%   dimensions events X channels X time (X frequency).
%
%   PARAMS is a structure that specifies options about how the pattern
%   should be created.  The pattern will be named PATNAME, and saved in
%   RESDIR (default is exp.resDir/eeg/patname).
%
%   Params:
%     'evname'          Name of the ev object to use (default: 'events')
%     'replace_eegfile' Cell array containing two strings to be passed
%                       in to strrep, to change the eegfile in events
%                       before it is loaded (default {})
%     'eventFilter'     Input to filterStruct that designates which
%                       events to use in creating the pattern
%     'baseEventFilter' Designates which events to use as baseline
%     'chanFilter'      Filters which channels are used to create the
%                       pattern
%     'resampledRate'   Rate to resample to (default 500)
%     'downsample'      Rate to downsample to (applies to power patterns)
%     'offsetMS'        Time in milliseconds to begin pattern relative
%                       to the start of each event
%     'durationMS'      Duration in milliseconds
%     'timeFilter'      Filters which times to include
%     'freqs'           Frequencies to include (applies to power patterns)
%     'freqFilter'      Filter for frequencies (applies to power patterns)
%     'lock'            If true (default), the pattern output file will be 
%                       locked during processing
%     'overwrite'       If false (default) and the pattern output file
%                       already exists for a subject, that subject will be
%                       skipped
%     'updateOnly'      If true (default is false), patterns will not be
%                       created, but exp will be updated with pat objects.
%                       This is useful if there were problems running
%                       subjects in parallel, and patterns were created
%                       but exp was not updated with metadata
%
%     Params also holds options specific to the particular pattern-
%     creation function that is used.
%   
%   To each subject a "pat" object will be added, which keeps track
%   of the metadata for each pattern.  Fields are:
%      name         String identifier of the pattern
%      file         Path to the .mat file holding the pattern
%      source       The identifier of the subject
%      params       A copy of the params struct used to create the pattern
%      dim          A struct that holds information about each dimension of 
%                   the pattern
%
%   Example:
%     params = struct('evname','events', 'offsetMS',-200, 'durationMS',1200);
%     exp = create_pattern(exp,@sessVoltage,params,'volt_pattern');
%     pat = getobj(exp.subj(1),'pat','volt_pattern');
%
%   See also sessVoltage, sessPower.

% input checks
if ~exist('resDir', 'var')
	resDir = fullfile(exp.resDir, patname);
end
if ~exist('patname', 'var')
	patname = 'pattern';
end
if ~exist('params', 'var')
	params = struct();
end
if ~exist('fcnhandle','var')
  error('You must specify a pattern-creation function.')
  elseif ~isa(fcnhandle,'function_handle')
  error('fcnhandle must be a function handle.')
  elseif ~exist('subj','var')
  error('You must pass a subject structure.')
  elseif ~isstruct(subj)
  error('subj must be a structure.')
end

% set the defaults for params 
params = structDefaults(params,  ...
                        'evname',           'events',   ...
                        'replace_eegfile',  {},         ... 
                        'eventFilter',      '',         ...
                        'chanFilter',       '',         ...
                        'resampledRate',    500,        ...
                        'downsample',       [],         ...
                        'offsetMS',         -200,       ...
                        'durationMS',       1800,       ...
                        'timeFilter',       '',         ...
                        'freqs',            [],         ...
                        'freqFilter',       '',         ...
                        'matlabpool_size',  [],          ...
                        'lock',             0,          ...
                        'overwrite',        0,          ...
                        'updateOnly',       0);

if ~isfield(params,'baseEventFilter')
  params.baseEventFilter = params.eventFilter;
end

% try to use parfor loops in gete_ms
if ~isempty(params.matlabpool_size)
  try
    matlabpool('open', params.matlabpool_size);
    catch
    fprintf('Unable to open matlabpool. gete_ms will be run in serial.');
  end
end

% get time bin information
if ~isempty(params.downsample)
  % ultimate sampling rate will be that given in downsample
	stepSize = fix(1000/params.downsample);
	else
	% use the resampling rate
	stepSize = fix(1000/params.resampledRate);
end
% make a vector of all millisecond values that will be in the finished pattern
MSvals = [params.offsetMS:stepSize:(params.offsetMS+params.durationMS-1)];

% create a "time" structure to keep track of the time dimension
time = init_time(MSvals);

% create a "freq" structure to keep track of the frequency dimension
freq = init_freq(params.freqs);

if ~params.updateOnly
  % display information about pattern creation
  fprintf('\nCreating patterns named %s using %s.\n', patname,func2str(fcnhandle))
  fprintf('Parameters are:\n\n')
  disp(params);
end

% set where the pattern will be saved
patfile = fullfile(resDir, 'patterns', sprintf('pattern_%s_%s.mat', patname, subj.id));

% check input files and prepare output files
if prepFiles({}, patfile, params)~=0
  return
end

% get this subject's events and baseline events
ev = getobj(subj, 'ev', params.evname);
src_events = loadEvents(ev.file, params.replace_eegfile);
base_events = filterStruct(src_events(:), params.baseEventFilter);

% create a pat object to keep track of this pattern
pat = init_pat(patname, patfile, subj.id, params, ev, subj.chan, time, freq);

% before we create any patterns, filter dimensions and update pat.dim.
% Note we can't filter time and frequency yet, we don't have them. That would
% be silly anyway, since we specify them in offsetMS, durationMS, resampledRate,
% downsample, and freq.
% We can, however, filter events and channels. Note that the source events
% and source channels are modified here, since we don't want to get data 
% just to filter it out later.
[pat,inds,src_events,evmod(1)] = patFilt(pat,params,src_events);

% use the modified chan struct to get our source channels
pat.params.channels = [pat.dim.chan.number];

% get the information we'll need later to create bins, and update pat.dim.
% To conserve memory, we'll do the actual binning as we accumlate the pattern.
[pat,bins,events,evmod(2)] = patBins(pat,params,src_events);

if any(evmod)
  % change the events name and file
  pat.dim.ev.name = sprintf('%s_mod', pat.dim.ev.name);
  pat.dim.ev.file = fullfile(resDir, 'events', sprintf('events_%s_%s.mat', patname, subj.id));

  % save the modified event struct to a new file
  if ~exist(fileparts(pat.dim.ev.file), 'dir')
    mkdir(fileparts(pat.dim.ev.file));
  end
  save(pat.dim.ev.file, 'events');
end

% we have finished modifying pat.dim! Update subj with the new pat object
subj = setobj(subj, 'pat', pat);

if params.updateOnly
  % in case we've already made patterns and need to re-update the exp struct
  closeFile(pat.file);
  fprintf('Pattern %s added to subj %s.\n', patname, subj.id)
  return
end

% initialize this subject's pattern
pattern = NaN(length(src_events), length(pat.dim.chan), length(pat.dim.time), length(pat.dim.freq));

% get a list of sessions in the filtered event struct
sessions = unique(getStructField(src_events, 'session'));

% CREATE THE PATTERN
for n=1:length(sessions)
  fprintf('\nProcessing %s session %d:\n', subj.id, sessions(n));
  
  % get the event indices for this session
  sessInd = inStruct(src_events, 'session==varargin{1}', sessions(n));
  
  % get the events and baseline events we need
  sess_events = src_events(sessInd);
  sess_base_events = filterStruct(base_events, 'session==varargin{1}', sessions(n));

  % make the pattern for this session
  pattern(sessInd,:,:,:) = fcnhandle(pat, bins, sess_events, sess_base_events);

end % session
fprintf('\n');

% channels, time, and frequency should already be binned. 
% Now we have all events and can bin across them.
pattern = patMeans(pattern, bins(1));

% save the pattern
save(pat.file,'pattern');
closeFile(pat.file);
fprintf('Pattern saved in %s.\n', pat.file)
