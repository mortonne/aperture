function subj = create_power_pattern(subj, pat_name, params, res_dir)
%CREATE_POWER_PATTERN   Create a power pattern for one subject.
%
%  subj = create_power_pattern(subj, pat_name, params, res_dir)
%
%  INPUTS:
%      subj:  a subject object. See get_sessdirs.
%
%  pat_name:  string identifier for the pattern. Default: 'power'
%
%    params:  structure that specifies options for pattern creation. See
%             below for options.
%
%   res_dir:  path to the directory to save results. patterns will be
%             saved in [res_dir]/patterns; if events are modified, new
%             events will be saved in [res_dir]/events.
%
%  OUTPUTS:
%      subj:  modified subject object, with a pattern object named
%             pat_name added.
%
%  PARAMS:
%  Defaults are shown in parentheses.
%   evname          - name of the events object to use. If empty, the
%                     last events added will be used. ('')
%   replace_eegfile - [N X 2] cell array, where each row contains two
%                     strings to be passed into strrep, to change the
%                     eegfile field in events. ({})
%   eventFilter     - input to filterStruct which designates which
%                     events to include in the pattern. ('')
%   chanFilter      - used to choose which channels to include in the
%                     pattern. Can be a string to pass into
%                     filterStruct, or an array of channel numbers to
%                     include. ('')
%   offsetMS        - time in milliseconds before each event to start
%                     the pattern. (-400)
%   durationMS      - duration in milliseconds of each epoch. (2400)
%   resampledRate   - samplerate (in Hz) to resample voltage before
%                     calculating power. ([])
%   downsample      - samplerate (in Hz) to downsample oscillatory
%                     power. ([])
%   filttype        - type of filter to use (see buttfilt). ('stop')
%   filtfreq        - frequency range for filter (see buttfilt).
%                     ([58 62])
%   filtorder       - order of filter (see buttfilt). (4)
%   bufferMS        - size of buffer to use when filtering (see
%                     buttfilt). (1000)
%   freqs           - REQUIRED - Frequencies (in Hz) at which to
%                     calculate power.
%   width           - width (in wavenumbers) of the Morlet wavelets to
%                     use for calculating oscillatory power. (6)
%   absThresh       - absolute threshold: if voltage (relative to
%                     baseline) of an event exceeds this value, power
%                     for that event will be excluded (replaced with
%                     NaNs). ([])
%   kthresh         - kurtosis threshold: if kurtosis of the raw voltage
%                     of any event exceeds this value, power for that
%                     event will be excluded (replaced with NaNs). ([])
%   logtransform    - logical; if true, power will be log-transformed.
%                     (true)
%   ztransform      - logical specifying whether to z-transform the
%                     power within each channel and frequency. (true)
%   baseEventFilter - input to filterStruct; designates which events to
%                     include for calculating the baseline 
%                     (eventFilter)
%   baseOffsetMS    - Time from the beginning of each baseline event to
%                     calculate power. (-400)
%   baseDurationMS  - Duration of the baseline period for each baseline
%                     event. (200)
%   precision       - precision of the returned values.
%                     ['single' | {'double'}]
%   overwrite       - if true, existing pattern files will be
%                     overwritten (false)
%   updateOnly      - if true, the pattern will not be created, but a
%                     pattern object will be created and attached to the
%                     subject object. (false)
%   verbose         - if true, more status will be printed. (false)
%
%   See also create_voltage_pattern.

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a subject object.')
elseif length(subj) > 1
  error('You must pass only one subject.')
end
if ~exist('params', 'var')
  params = struct;
elseif ~isstruct(params)
  error('params must be a structure.')
end
if ~exist('pat_name', 'var')
  pat_name = 'power';
elseif ~ischar(pat_name)
  error('pat_name must be a string.')
end
if ~exist('res_dir', 'var')
  error('You give a path to a directory in which to save results.')
elseif ~ischar(res_dir)
  error('res_dir must be a string.')
end

% to overwrite defaults that overlap between create_pattern
% and sessPower
defaults.offsetMS = -400;
defaults.durationMS = 2400;

params = propval(params, defaults, 'strict', false);

subj = create_pattern(subj, @sessPower, params, pat_name, res_dir);
