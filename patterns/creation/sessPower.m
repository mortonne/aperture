function [pattern, params] = sessPower(events, channels, params, ...
                                       base_events, bins)
%SESSPOWER   Create a pattern of oscillatory power for one session.
%
%  [pattern, params] = sessPower(events, channels, params, base_events, bins)
%
%  Calculate oscillatory power using Morlet wavelets for all events in
%  an events structure.
%
%  Power is calculated for one session at a time because there is
%  assumed to be variation in electrode position, impedance, etc. that
%  changes between sessions. This variation can be dealt with by
%  z-transforming within each session, channel, and frequency by setting
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
%       params:  structure with the full set of options used to create
%                the pattern.
%
%  PARAMS:
%  Defaults are shown in parentheses.
%   freqs          - REQUIRED - Frequencies (in Hz) at which to
%                    calculate power.
%   offsetMS       - time in milliseconds before each event to start the
%                    pattern. (-400)
%   durationMS     - duration in milliseconds of each epoch. (2400)
%   resampledRate  - samplerate (in Hz) to resample voltage before
%                    calculating power. ([])
%   downsample     - samplerate (in Hz) to downsample oscillatory
%                    power. ([])
%   filttype       - type of filter to use (see buttfilt). ('stop')
%   filtfreq       - frequency range for filter (see buttfilt).
%                    ([58 62])
%   filtorder      - order of filter (see buttfilt). (4)
%   bufferMS       - size of buffer to use when filtering (see
%                    buttfilt). (1000)
%   width          - width (in wavenumbers) of the Morlet wavelets to
%                    use for calculating oscillatory power. (6)
%   absThresh      - absolute threshold: if voltage (relative to
%                    baseline) of an event exceeds this value, power for
%                    that event will be excluded (replaced with NaNs).
%                    ([])
%   kthresh        - kurtosis threshold: if kurtosis of the raw voltage 
%                    of any event exceeds this value, power for that
%                    event will be excluded (replaced with NaNs). ([])
%   logtransform   - logical; if true, power will be log-transformed.
%                    (true)
%   ztransform     - logical specifying whether to z-transform the
%                    power within each channel and frequency. (true)
%   baseOffsetMS   - Time from the beginning of each baseline event to
%                    calculate power. (-400)
%   baseDurationMS - Duration of the baseline period for each baseline
%                    event. (200)
%   precision      - precision of the returned values.
%                    ['single' | {'double'}]
%   verbose        - if true, more status will be printed. (false)
%
%  See also create_power_pattern, sessVoltage.

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
if ~isfield(params, 'freqs') || isempty(params.freqs)
  error('You must specify frequencies at which to calculate power.')
end

% default parameters
defaults.freqs = [];
defaults.offsetMS = -400;
defaults.durationMS = 2400;
defaults.resampledRate = [];
defaults.downsample = [];
defaults.filttype = 'stop';
defaults.filtfreq = [58 62];
defaults.filtorder = 4;
defaults.bufferMS = 1000;
defaults.width = 6;
defaults.precision = 'double';
defaults.absThresh = [];
defaults.kthresh = [];
defaults.logtransform = true;
defaults.ztransform = true;
defaults.baseOffsetMS = -400;
defaults.baseDurationMS = 200;
defaults.verbose = false;

[params, unused] = propval(params, defaults);

if params.verbose
  fprintf('parameters are:\n\n')
  disp(params)
end

% set parameters for the baseline period
if params.ztransform
  if ~exist('base_events', 'var') || isempty(base_events)
    base_events = events;
  elseif ~isstruct(base_events)
    error('base_events must be a structure.')
  end

  % translate to standard names
  base_params = params;
  base_params.offsetMS = params.baseOffsetMS;
  base_params.durationMS = params.baseDurationMS;
end

% figure out what the final samplerate will be
if ~isempty(params.downsample)
  final_samplerate = params.downsample;
elseif ~isempty(params.resampledRate)
  final_samplerate = params.resampledRate;
else
  % it's just the minimum samplerate
  final_samplerate = unique(get_events_samplerate(events));
  if length(final_samplerate) > 1
    final_samplerate = min(final_samplerate);
    params.resampledRate = final_samplerate;
    fprintf(['Events contain multiple samplerates. ' ...
             'Resampling to %d Hz...\n'], params.resampledRate)
  end
end
duration_samp = ms2samp(params.durationMS, final_samplerate);

% initialize the pattern for this session
start_size = [length(events), length(channels), ...
              duration_samp, length(params.freqs)];
end_size = cellfun(@length, bins);
empty_bins = end_size==0;
end_size(empty_bins) = start_size(empty_bins);
pattern = NaN(end_size(1), start_size(2), end_size(3), end_size(4), ...
              params.precision);

fprintf('channels: ')
for c=1:length(channels)
  % get the current channel number
  channel = channels(c);
  fprintf('%d ', channel);

  % if z-transforming, get baseline stats for this sess, channel
  if params.ztransform
    base_power = get_power(base_events, channel, base_params);
    [base_mean, base_std] = baseline_stats(base_power);
  end

  % get [events X time X frequency] power
  power = get_power(events, channel, params);
  
  % normalize within this session, channel, and frequency
  if params.ztransform
    for f=1:size(power, 3)
      power(:,:,f) = (power(:,:,f) - base_mean(f)) / base_std(f);
    end
  end
  
  % apply event, time, and frequency binning
  power = patMeans(power, [bins(1) bins(3:4)]);
  
  % add this channel to the pattern
  pattern(:,c,:,:) = power;
end
fprintf('\n')

% bin channels
bins([1 3:4]) = {[]};
pattern = patMeans(pattern, bins);


function power = get_power(events, channel, params)
  %GET_POWER   Get power values for a set of events.
  %
  %  power = get_power(events, channel, params)
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
                      params.offsetMS, p, p.verbose);

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
  base_mean = NaN(1, size(base_power, 3));
  base_std = NaN(1, size(base_power, 3));
  
  % get baseline stats
  for f=1:size(base_power, 3)
    % power just for this frequency
    freq_base_pow = base_power(:,:,f);
    
    % get mean and std dev across events for each sample,
    % then average across samples
    base_mean(f) = nanmean(nanmean(freq_base_pow, 1));
    base_std(f) = nanmean(nanstd(freq_base_pow, 1));
  end
%endfunction
