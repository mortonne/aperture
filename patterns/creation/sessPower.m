function pattern = sessPower(pat, events, base_events, bins)
%SESSPOWER   Create a power pattern for one session.
%
%  pattern = sessPower(pat, events, base_events, bins)
%
%  Power is calculated using Morlet wavelets for all events in the event
%  structure using getphasepow. The result is stored in a matrix called
%  a "pattern."
%
%  Power is calculated for one session at a time because there is
%  assumed to be variation in electrode position, impedance, etc. that
%  changes between sessions. This variation can be dealt with by
%  z-transforming within each session, channel, and frequency.
%
%  INPUTS:
%          pat:  structure that holds metadata for a pattern (see
%                create_pattern for details). The options in pat.params
%                affect how the pattern is created, and pat.dim is used
%                to initialize the pattern.
%
%       events:  an events structure. This should contain every event
%                you want power for.
%
%  base_events:  an events structure. If params.ztransform is true,
%                These events will be used to calculate baseline power
%                for z-transforming. If empty or ommitted, events will
%                be used.
%
%         bins:  cell array with one cell for each dimension of pattern;
%                each cell should contain a cell array, and each cell
%                contains indices for one bin. If a cell is empty, no
%                binning will take place for that dimension.
%                Default: {[],[],[],[]}
%
%  OUTPUTS:
%      pattern:  an [events X channel X time X frequency] matrix
%                containing power values.
%
%  pat.params can contain the following fields to specify options for
%  creating the pattern:
%
%  PARAMS:
%  Defaults are shown in parentheses.
%  channels       - REQUIRED - channels to calculate power for.
%  freqs          - REQUIRED - Frequencies (in Hz) at which to calculate
%                   power.
%  baseOffsetMS   - Time from the beginning of each baseline event to
%                   calculate power. (-200)
%  baseDurationMS - Duration of the baseline period for each baseline
%                   event. (100)
%  filttype       - Type of filter to use (see buttfilt). ('stop')
%  filtfreq       - Frequency range for filter (see buttfilt). ([58 62])
%  filtorder      - Order of filter (see buttfilt). (4)
%  bufferMS       - Size of buffer to use when filtering (see buttfilt)
%                   (1000)
%  width          - Size of wavelets to use in power calculation
%                   (see getphasepow). (6)
%  precision      - precision of the returned values.
%                   ['single' | {'double'}]
%  absThresh      - absolute threshold: if voltage (relative to
%                   baseline) of an event exceeds this value, power for
%                   that event will be excluded (replaced with NaNs).
%                   ([])
%  kthresh        - Kurtosis threshold: if kurtosis of the raw voltage 
%                   of any event exceeds this value, power for that
%                   event will be excluded (replaced with NaNs). ([])
%  ztransform     - Logical specifying whether to z-transform the power.
%                   (false)
%  logtransform   - Logical specifying whether to log-transform the
%                   power. (false)
%
%  See also create_pattern, sessVoltage.

warning('off', 'eeg_ana:patBinAllNaNs')

% input checks
if ~exist('pat', 'var')
  error('You must pass a pat object.')
elseif ~exist('events', 'var') || ~isstruct(events)
  error('You must pass an events structure.')
end
if ~exist('base_events', 'var') || isempty(base_events)
  base_events = events;
elseif ~isstruct(base_events)
  error('base_events must be a structure.')
end
if ~exist('bins', 'var')
  bins = cell(1,4);
end

% set defaults for pattern creation
params = structDefaults(pat.params, ...
                        'baseOffsetMS',    -200,     ...
                        'baseDurationMS',  100,      ...
                        'filttype',        'stop',   ...
                        'filtfreq',        [58 62],  ...
                        'filtorder',       4,        ...
                        'bufferMS',        1000,     ...
                        'width',           6,        ...
                        'absThresh',       [],       ...
                        'kthresh',         [],       ...
                        'ztransform',      false,    ...
                        'logtransform',    false,    ...
                        'precision',       'single');

if ~isfield(params, 'freqs') || isempty(params.freqs)
  error('You must specify frequencies at which to calculate power.')
elseif ~isfield(params, 'channels') || isempty(params.channels)
  error('You must specify channels at which to calculate power.')
end

% initialize the pattern for this session
pattern = NaN(length(events), length(params.channels), ...
              length(pat.dim.time), length(pat.dim.freq), params.precision);

% set parameters for the baseline period
base_params = params;
base_params.durationMS = params.baseDurationMS;
base_params.offsetMS = params.baseOffsetMS;

fprintf('Channels: ')
for c=1:length(params.channels)
  % get the current channel number
  channel = params.channels(c);
  fprintf('%d ', channel);

  % if z-transforming, get baseline stats for this sess, channel
  if params.ztransform
    base_power = get_power(base_events, channel, base_params);
    [base_mean, base_std] = baseline_stats(base_power);
  end

  % get power, remove artifacts, do binning of time and frequency
  for e=1:length(events)
    % get power for this event in [time X frequency] form
    power = permute(get_power(events(e), channel, params), [2 3 1]);

    % z-transform
    if params.ztransform
      for f=1:size(power,2)
        power(:,f) = (power(:,f) - base_mean(f)) / base_std(f);
      end
    end

    % bin time and frequency, and add the power of this eventXchannel
    pattern(e,c,:,:) = patMeans(power, bins(3:4));
  end
end

% bin channels
bins([1 3:4]) = {[]};
pattern = patMeans(pattern, bins);


function power = get_power(events, channel, params)
  %GET_POWER   Get power values for a set of events.
  %
  %  power = get_power(events, params)
  %
  %  INPUTS:
  %   events:  an events structure.
  %
  %  channel:  number of the channel to calculate power for.
  %
  %   params:  a params structure.
  %
  %  OUTPUTS:
  %    power:  power values in an [events X time X frequency]
  %            matrix.

  % input checks
  if ~exist('events','var')
    error('You must pass an events structure.')
  elseif ~exist('channel','var') || ~isnumeric(channel)
    error('You must indicate the number of the channel to use.')
  elseif ~exist('params','var') || ~isstruct(params)
    error('You must pass a params structure.')
  end

  % using version in eeg_toolbox/branches/unstable...
  % calculate power from raw voltage for a set of frequencies
  p = params;
  p.absthresh = params.absThresh;
  p.resampledrate = params.resampledRate;
  power = getphasepow(events, channel, params.freqs, params.durationMS, ...
                      params.offsetMS, p);

  % sanity check the power values
  if any(power(:) < 0)
    error('sessPower: getphasepow returned negative power values.')
  elseif isempty(power)
    error('sessPower: getphasepow returned an empty array.')
  end
  
  % change the order of dimensions to [events X time X frequency]
  power = permute(power, [1 3 2]);
  
  % log transform if desired
  if params.logtransform
    % if any values are exactly 0, make them eps
    power(power==0) = eps(0);
    power = log10(power);
  end
%endfunction

function [base_mean, base_std] = baseline_stats(base_power)
  %BASELINE_STATS   Get baseline statistics for each frequency.
  %
  %  [base_mean, base_std] = baseline_stats(power)
  %
  %  INPUTS:
  %  base_power:  an [events X time X frequency] matrix of power
  %               values.
  %
  %  OUTPUTS:
  %   base_mean:  [1 X frequency] vector of means.
  %
  %    base_std:  [1 X frequency] vector of standard deviations.
  
  % initialize
  base_mean = NaN(1,size(base_power,3));
  base_std = NaN(1,size(base_power,3));
  
  % get baseline stats
  for f=1:size(base_power,3)
    % power just for this frequency
    freq_base_pow = base_power(:,:,f);
    
    % get mean and std dev across events for each sample,
    % then average across samples
    base_mean(f) = nanmean(nanmean(freq_base_pow,1));
    base_std(f) = nanmean(nanstd(freq_base_pow,1));
  end
%endfunction
