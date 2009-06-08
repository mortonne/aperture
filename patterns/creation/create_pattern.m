function subj = create_pattern(subj, fcn_handle, params, pat_name, res_dir)
%CREATE_PATTERN   Create a pattern for a subject.
%
%  subj = create_pattern(subj, fcn_handle, params, pat_name, res_dir)
%
%  INPUTS:
%        subj:  a subject object. See get_sessdirs.
%
%  fcn_handle:  handle to a function that returns an
%               [events X channels X time (X frequency)] matrix for one
%               session. Must be of the form:
%                pattern = fcn_handle(pat, events, base_events, bins)
%               where "pat" is a standard pattern object. See sessVoltage
%               and sessPower for examples of compatible functions.
%
%      params:  structure that specifies options for pattern creation.
%               See below. Can also contain options for fcn_handle, which
%               are passed to it as pat.params
%
%    pat_name:  string identifier for the pattern.
%
%     res_dir:  path to the directory to save results. patterns will be
%               saved in [res_dir]/patterns; if events are modified,
%               new events will be saved in [res_dir]/events.
%
%  OUTPUTS:
%        subj:  a modified subject object, with a "pat" object named
%               patname added.
%
%  PARAMS:
%  All fields are optional. Defaults are shown in parentheses.
%   evname          - name of the events object to use. ('events')
%   replace_eegfile - [N X 2] cell array, where each row contains two
%                     strings to be passed into strrep, to change the
%                     eegfile field in events ({})
%   eventFilter     - input to filterStruct which designates which
%                     events to include in the pattern ('')
%   chanFilter      - used to choose which channels to include in the
%                     pattern. Can a string to pass into filterStruct,
%                     or an array of channel numbers to include ('')
%   resampledRate   - rate to resample to (500)
%   downsample      - rate to downsample to (applies to power patterns)
%                     ([])
%   offsetMS        - time in milliseconds before each event to start
%                     the pattern (-200)
%   durationMS      - duration in milliseconds of each epoch (2200)
%   freqs           - for patterns with a frequency dimension, specifies
%                     which frequencies (in Hz) the pattern should 
%                     include ([])
%   lock            - if true, the pattern's file will be locked during
%                     pattern creation, and unlock when the program
%                     finishes. Useful for processing multiple subjects
%                     in parallel on a cluster. (false)
%   overwrite       - if true, existing pattern files will be overwritten
%   updateOnly      - if true, the pattern will not be created, but a
%                     pattern object will be created and attached to the
%                     subject object.
%
%  See also create_voltage_pattern, create_power_pattern.

% input checks
if ~exist('subj','var') || ~isstruct(subj)
  error('You must pass a subject object.')
elseif length(subj)>1
  error('You must pass only one subject.')
elseif ~all(isfield(subj, {'id','chan','ev'}))
  error('The subject object must have "id", "chan", and "ev" fields.')
elseif ~exist('fcn_handle','var') || ~isa(fcn_handle, 'function_handle')
  error('You must pass a function handle.')
end
if ~exist('params','var')
  params = struct;
elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~exist('pat_name','var')
  pat_name = 'pattern';
elseif ~ischar(pat_name)
  error('pat_name must be a string.')
end
if ~exist('res_dir', 'var')
  error('You give a path to a directory in which to save results.')
elseif ~ischar(res_dir)
  error('res_dir must be a string.')
end

% default parameters
params = structDefaults(params,  ...
                        'evname',           'events',   ...
                        'replace_eegfile',  {},         ... 
                        'eventFilter',      '',         ...
                        'chanFilter',       '',         ...
                        'resampledRate',    500,        ...
                        'downsample',       [],         ...
                        'offsetMS',         -200,       ...
                        'durationMS',       2200,       ...
                        'timeFilter',       '',         ...
                        'freqs',            [],         ...
                        'freqFilter',       '',         ...
                        'lock',             false,      ...
                        'overwrite',        false,      ...
                        'updateOnly',       false);

if ~isfield(params,'baseEventFilter')
  params.baseEventFilter = params.eventFilter;
end

% set where the pattern will be saved
pat_file = fullfile(res_dir, 'patterns', sprintf('pattern_%s_%s.mat', pat_name, subj.id));

% print status and final parameters
if ~params.updateOnly
  fprintf('creating pattern for %s named %s using %s.\n', subj.id, pat_name, func2str(fcn_handle))
end

% events dimension
ev = getobj(subj, 'ev', params.evname);
ev = move_obj_to_workspace(ev);
% fix the EEG file field if needed
if ~isempty(params.replace_eegfile)
  temp = params.replace_eegfile';
  ev.mat = rep_eegfile(ev.mat, temp{:});
end
base_events = filterStruct(ev.mat, params.baseEventFilter);

% channels dimension
chan = subj.chan;

% time dimension
if ~isempty(params.downsample)
	stepSize = fix(1000/params.downsample);
else
	stepSize = fix(1000/params.resampledRate);
end
% millisecond values for the final pattern
ms_values = params.offsetMS:stepSize:(params.offsetMS+params.durationMS-1);
time = init_time(ms_values);

% frequency dimension
freq = init_freq(params.freqs);

% create a pat object to keep track of this pattern
pat = init_pat(pat_name, pat_file, subj.id, params, ev, chan, time, freq);

% filter events and channels
try
  pat = patFilt(pat, params);
catch err
  id = get_error_id(err);
  if strcmp(id, 'EmptyPattern')
    fprintf('Filtering will remove a dimension of the pattern. Aborting pattern creation...\n')
    return
  end
end

src_events = get_mat(pat.dim.ev);
pat.params.channels = [pat.dim.chan.number];

% get the information we'll need later to create bins, and update pat.dim.
% to conserve memory, we'll do the actual binning as we accumulate the pattern.
[pat, bins] = patBins(pat, params);

% finalize events for the pattern
if pat.dim.ev.modified
  % save the modified events struct to a new file
  events_dir = get_pat_dir(pat, 'events');  
  pat.dim.ev.file = fullfile(events_dir, sprintf('events_%s_%s.mat', pat_name, subj.id));
end
pat.dim.ev = move_obj_to_hd(pat.dim.ev, true);

% update subj with the new pat object
subj = setobj(subj, 'pat', pat);

% check the output file
try
  prepFiles({}, pat.file, params);
catch err
  if strfind(err.identifier, 'fileExists')
    fprintf('file exists. Skipping...\n')
    return
  else
    rethrow(err)
  end
end

% if we just want to update the subject object, we're done
if params.updateOnly
  closeFile(pat.file);
  fprintf('Pattern %s added to subj %s.\n', pat_name, subj.id)
  return
end

% initialize this subject's pattern before event binning
pat_size = patsize(pat.dim);
pattern = NaN([length(src_events), pat_size(2:end)]);

% create a pattern for each session in the events structure
for session=unique([src_events.session])
  fprintf('\nProcessing %s session %d:\n', subj.id, session)

  % get the events and baseline events we need
  sess_ind = [src_events.session]==session;
  sess_events = src_events(sess_ind);
  sess_base_events = base_events([base_events.session]==session);

  % make the pattern for this session
  pattern(sess_ind,:,:,:) = fcn_handle(pat, sess_events, sess_base_events, bins);
end
fprintf('\n')

% channels, time, and frequency should already be binned. 
% now we have all events and can bin across them.
pattern = patMeans(pattern, bins(1));

% save the pattern
save(pat.file, 'pattern');
fprintf('Pattern saved in %s.\n', pat.file)

% unlock the pattern file if needed
closeFile(pat.file);
