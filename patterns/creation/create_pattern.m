function subj = create_pattern(subj, fcn_handle, params, pat_name, res_dir)
%CREATE_PATTERN   Create a pattern for a subject.
%
%  subj = create_pattern(subj, fcn_handle, params, pat_name, res_dir)
%
%  INPUTS:
%        subj:  subject object. See get_sessdirs.
%
%  fcn_handle:  handle to a function that returns an
%               [events X channels X time (X frequency)] matrix for one
%               session. Must be of the form:
%                [pattern, params] = fcn_handle(events, channels, ...
%                                     params, base_events, bins)
%               See sessVoltage and sessPower for examples of compatible
%               functions.
%
%      params:  structure that specifies options for pattern creation.
%               See below.  params will also be passed to fcn_handle.
%
%    pat_name:  string identifier for the pattern.
%
%     res_dir:  path to the directory to save results. patterns will be
%               saved in [res_dir]/patterns; if events are modified,
%               new events will be saved in [res_dir]/events.
%
%  OUTPUTS:
%        subj:  modified subject object, with a "pat" object named
%               pat_name added.
%
%  PARAMS:
%  All fields are optional. Defaults are shown in parentheses.
%   evname          - name of the events object to use. If empty, the
%                     last events added will be used. ('')
%   replace_eegfile - [N X 2] cell array, where each row contains two
%                     strings to be passed into strrep, to change the
%                     eegfile field in events. ({})
%   eventFilter     - input to filterStruct which designates which
%                     events to include in the pattern. ('')
%   baseEventFilter - input to filterStruct; designates which events to
%                     include in calculating a baseline for
%                     z-transforming. (eventFilter)
%   chanFilter      - used to choose which channels to include in the
%                     pattern. Can be a string to pass into
%                     filterStruct, or an array of channel numbers to
%                     include. ('')
%   offsetMS        - time in milliseconds before each event to start
%                     the pattern. (-200)
%   durationMS      - duration in milliseconds of each epoch. (2200)
%   resampledRate   - samplerate (in Hz) to resample to. ([])
%   downsample      - samplerate (in Hz) to downsample oscillatory
%                     power. ([])
%   freqs           - for patterns with a frequency dimension, specifies
%                     which frequencies (in Hz) the pattern should 
%                     include ([])
%   precision       - precision of the returned values.
%                     ['single' | {'double'}]
%   overwrite       - if true, existing pattern files will be
%                     overwritten (false)
%   updateOnly      - if true, the pattern will not be created, but a
%                     pattern object will be created and attached to the
%                     subject object. (false)
%
%  See also create_voltage_pattern, create_power_pattern.

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a subject object.')
elseif length(subj) > 1
  error('You must pass only one subject.')
elseif ~all(isfield(subj, {'id', 'chan', 'ev'}))
  error('The subject object must have "id", "chan", and "ev" fields.')
elseif ~exist('fcn_handle', 'var') || ~isa(fcn_handle, 'function_handle')
  error('You must pass a function handle.')
end
if ~exist('params', 'var')
  params = struct;
end
if ~exist('pat_name', 'var')
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
defaults.evname = '';
defaults.replace_eegfile = {};
defaults.eventFilter = '';
defaults.baseEventFilter = '';
defaults.chanFilter = '';
defaults.offsetMS = -200;
defaults.durationMS = 2200;
defaults.resampledRate = [];
defaults.downsample = [];
defaults.freqs = [];
defaults.precision = 'double';
defaults.overwrite = false;
defaults.updateOnly = false;

params = propval(params, defaults, 'strict', false);

if ~isfield(params, 'baseEventFilter')
  params.baseEventFilter = params.eventFilter;
end

% print status
if ~params.updateOnly
  fprintf('creating "%s" pattern from "%s" events using %s...\n', ...
          pat_name, params.evname, func2str(fcn_handle))
end

% set where the pattern will be saved
pat_dir = fullfile(res_dir, 'patterns');
pat_file = fullfile(pat_dir, objfilename('pattern', pat_name, subj.id));

if ~params.overwrite && exist(pat_file, 'file')
  fprintf('pattern exists in %s.\nskipping...\n', pat_file)
  return
end
if ~exist(res_dir, 'dir')
  mkdir(res_dir);
end
if ~exist(pat_dir, 'dir')
  mkdir(pat_dir)
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

% get channel info from the subject
chan = get_dim(subj, 'chan');

% time dimension
if ~isempty(params.downsample)
  step_size = fix(1000 / params.downsample);
else
  if isempty(params.resampledRate)
    % if not resampling, we'll need to know the samplerate of the data
    % so we can initialize the pattern.
    eegfiles = unique({ev.mat.eegfile});
    samplerates = cellfun(@(x)GetRateAndFormat(fileparts(x)), eegfiles);
    if length(unique(samplerates)) > 1
      params.resampledRate = min(samplerates);
      fprintf(['events contain multiple samplerates. ' ...
               'Resampling to %d Hz...\n'], params.resampledRate)
    else
      params.resampledRate = unique(samplerates);
    end
  end
  step_size = fix(1000 / params.resampledRate);
end
% millisecond values for the final pattern
end_ms = params.offsetMS + params.durationMS - step_size;
ms_values = params.offsetMS:step_size:end_ms;
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
    error('Filtering will remove a dimension of the pattern.')
  else
    rethrow(err)
  end
end

% get updated events and channels before doing binning
src_events = get_mat(pat.dim.ev);
channels = get_dim_vals(pat.dim, 'chan');

% get the information we'll need later to create bins, and update
% pat.dim. to conserve memory, we'll do the actual binning as we
% accumulate the pattern.
[pat, bins] = patBins(pat, params);

% finalize events for the pattern
if pat.dim.ev.modified
  % save the modified events struct to a new file
  pat.dim.ev.file = fullfile(get_pat_dir(pat, 'events'), ...
                             objfilename('events', pat_name, subj.id));
end
pat.dim.ev = move_obj_to_hd(pat.dim.ev, true);

% if we just want to update the subject object, we're done
if params.updateOnly
  fprintf('pattern %s added to subj %s.\n', pat_name, subj.id)
  subj = setobj(subj, 'pat', pat);
  return
end

% initialize this subject's pattern before event binning
pat_size = patsize(pat.dim);
pattern = NaN([length(src_events), pat_size(2:end)], params.precision);

% don't bin over events until we have all sessions
event_bins = bins(1);
bins(1) = {[]};

% create a pattern for each session in the events structure
for session=unique([src_events.session])
  fprintf('processing %s session %d...\n', subj.id, session)

  % get the events and baseline events we need
  sess_ind = [src_events.session]==session;
  sess_events = src_events(sess_ind);
  sess_base_events = base_events([base_events.session]==session);

  % make the pattern for this session
  [pattern(sess_ind,:,:,:), p] = fcn_handle(sess_events, channels, params, ...
                                            sess_base_events, bins);
end
pat.params = combineStructs(params, p);

% channels, time, and frequency should already be binned. 
% now we have all events and can bin across them.
pattern = patMeans(pattern, event_bins);

% save the pattern
pat = set_mat(pat, pattern, 'hd');
fprintf('pattern saved in %s.\n', pat.file)

% update subj with the new pat object
subj = setobj(subj, 'pat', pat);

