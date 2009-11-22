function [pattern, params] = sessVoltage(events, channels, params, ...
                                        base_events, bins)
%SESSVOLTAGE   Create a voltage pattern for one session.
%
%  [pattern, params] = sessVoltage(events, channels, params, base_events, bins)
%
%  Voltage is calculated for one session at a time because there is
%  assumed to be variation in electrode position, impedance, etc. that
%  changes between sessions. This variation can be dealt with by
%  z-transforming within each session, and channel by setting
%  params.ztransform to true.
%
%  INPUTS:
%       events:  an events structure. Must have "eegfile" and
%                "eegoffset" fields.
%
%     channels:  vector of channel numbers to include in the pattern.
%
%       params:  structure giving options for creating the pattern.  See
%                below.
%
%  base_events:  an events structure. If params.ztransform is true,
%                These events will be used to calculate baseline voltage
%                for z-transforming. If empty or ommitted, events will
%                be used.
%
%         bins:  cell array with one cell for each dimension of pattern;
%                each cell should contain a cell array, and each cell
%                contains indices for one bin. If a cell is empty, no
%                binning will take place for that dimension.
%                Default: {[],[],[]}
%
%  OUTPUTS:
%      pattern:  an [events X channel X time] matrix containing voltage
%                or z-transformed voltage values.
%
%       params:  structure with the full set of options used to create
%                the pattern.
%
%  PARAMS:
%  All fields are optional.  Defaults are shown in parentheses.
%   offsetMS       - time in milliseconds before each event to start the
%                    pattern. (-200)
%   durationMS     - duration in milliseconds of each epoch. (2200)
%   relativeMS     - period in milliseconds to use for calculating the
%                    average to be subtracted for each event. ([-200 0])
%   resampledRate  - samplerate (in Hz) to resample to. ([])
%   filttype       - type of filter to use (see buttfilt). ('low')
%   filtfreq       - frequency range for filter (see buttfilt). (40)
%   filtorder      - order of filter (see buttfilt). (4)
%   bufferMS       - size of buffer to use when filtering (see buttfilt)
%                    (1000)
%   precision      - precision of the returned values.
%                    ['single' | {'double'}]
%   ztransform     - logical specifying whether to z-transform the
%                    voltage. (false)
%   baseOffsetMS   - time from the beginning of each baseline event to
%                    calculate voltage. (relativeMS(1))
%   baseDurationMS - duration of the baseline period for each baseline
%                    event. (diff(relativeMS))
%   baseRelativeMS - period to use for baseline subtraction for the
%                    baseline period. (relativeMS)
%   verbose        - if true, more status will be printed. (false)
%
%  See also create_voltage_pattern, sessPower.

% input checks
if ~exist('events', 'var') || ~isstruct(events)
  error('You must pass an events structure.')
elseif ~exist('channels', 'var') || ~isnumeric(channels)
  error('You must specify channels at which to calculate voltage.')
end
if ~exist('params', 'var') || isempty(params)
  params = struct;
end
if ~exist('bins', 'var')
  bins = cell(1, 4);
end
if any(isfield(params, {'kthresh', 'absThresh', 'artWindow', ...
                        'excludeBadChans'}))
  warning('Artifact rejection no longer supported. Use modify_pattern.')
end

% default parameters
defaults.offsetMS = -200;
defaults.durationMS = 2200;
defaults.relativeMS = [-200 0];
defaults.resampledRate = [];
defaults.filttype = 'low';
defaults.filtfreq = 40;
defaults.filtorder = 4;
defaults.bufferMS = 1000;
defaults.precision = 'double';
defaults.ztransform = false;
defaults.verbose = false;

[params, unused] = propval(params, defaults);

% set parameters for the baseline period
if params.ztransform
  if ~exist('base_events', 'var') || isempty(base_events)
    base_events = events;
  elseif ~isstruct(base_events)
    error('base_events must be a structure.')
  end
  
  % set defaults
  defaults = [];
  defaults.baseOffsetMS = params.relativeMS(1);
  defaults.baseDurationMS = diff(params.relativeMS);
  defaults.baseRelativeMS = params.relativeMS;
  [temp, unused] = propval(unused, defaults);
  
  % translate to standard names
  base_params = params;
  base_params.offsetMS = temp.baseOffsetMS;
  base_params.durationMS = temp.baseDurationMS;
  base_params.relativeMS = temp.baseRelativeMS;
  params = combineStructs(params, temp);
end

if params.verbose
  fprintf('parameters are:\n\n')
  disp(params)
end

if isempty(params.resampledRate)
  % if not resampling, we'll need to know the samplerate of the data
  % so we can initialize the pattern.
  final_samplerate = unique(get_events_samplerate(events));
  if length(final_samplerate) > 1
    final_samplerate = min(final_samplerate);
    params.resampledRate = final_samplerate;
    fprintf(['Events contain multiple samplerates. ' ...
             'Resampling to %d Hz...\n'], params.resampledRate)
  end
else
  final_samplerate = params.resampledRate;
end
duration_samp = ms2samp(params.durationMS, final_samplerate);

% initialize the pattern for this session
start_size = [length(events), length(channels), duration_samp];
end_size = cellfun(@length, bins);
empty_bins = end_size==0;
end_size(empty_bins) = start_size(empty_bins);
pattern = NaN(end_size(1), start_size(2), end_size(3), params.precision);

fprintf('channels: ')
for c=1:length(channels)
  % get the current channel number
  channel = channels(c);
  fprintf('%d ', channel);

  % get baseline stats for this channel, sess
  if params.ztransform
    % get [events X time] voltage
    base_eeg = get_eeg(base_events, channel, base_params);

    % get mean and std dev across events for each sample, then average
    % across samples
    base_mean = nanmean(nanmean(base_eeg, 1));
    base_std = nanmean(nanstd(base_eeg, 1));
  end

  % get [events X time] voltage
  this_eeg = get_eeg(events, channel, params);

  % normalize within this session and channel
  if params.ztransform
    this_eeg = (this_eeg - base_mean) / base_std;
  end

  % apply event and time binning
  this_eeg = patMeans(this_eeg, [bins(1) bins(3)]);
  
  % add this channel to the pattern
  pattern(:,c,:) = this_eeg;
end
fprintf('\n')

% apply channel binning
bins([1 3]) = {[]};
pattern = patMeans(pattern, bins);

function eeg = get_eeg(events, channel, params)
  %GET_EEG   Get voltage values for a set of events.
  %
  %  eeg = get_eeg(events, channel, params)

  % get an [events X time] matrix of voltage values
  eeg = gete_ms(channel,              ...
                events,               ...
                params.durationMS,    ...
                params.offsetMS,      ...
                params.bufferMS,      ... 
                params.filtfreq,      ...
                params.filttype,      ...
                params.filtorder,     ...
                params.resampledRate, ...
                params.relativeMS);
%endfunction

