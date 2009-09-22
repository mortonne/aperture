function pattern = sessPower(pat,events,base_events,bins)
%SESSPOWER   Create a power pattern for one session.
%
%  pattern = sessPower(pat, events, base_events, bins)
%
%  Power is calculated using Morlet wavelets for all events in the event 
%  structure using getphasepow. The result is stored in a matrix called
%  a "pattern."
%
%  Power is calculated for one session at a time because there is assumed
%  to be variation in electrode position, impedance, etc. that changes
%  between sessions. This variation can be dealt with by z-transforming
%  within each session, channel, and frequency.
%
%  In a future version of this function, the pat object will not be part
%  of the inputs; instead, params, events, and bins will determine everything.
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
%  base_events:  an events structure. If params.ztransform is true, These 
%                events will be used to calculate baseline power for 
%                z-transforming. If empty or ommitted, events will be used.
%
%         bins:  cell array with one cell for each dimension of pattern;
%                each cell should contain a cell array, and each cell
%                contains indices for one bin. If a cell is empty, no
%                binning will take place for that dimension.
%                Default: {[],[],[],[]}
%
%  OUTPUTS:
%      pattern:  an [events X channel X time X frequency] matrix containing
%                power values.
%
%  pat.params can contain the following fields to specify options for creating
%  the pattern:
%
%  PARAMS:
%  baseOffsetMS   - Time from the beginning of each baseline event to
%                   calculate power.
%  baseDurationMS - Duration of the baseline period for each baseline
%                   event (currently doesn't matter, since the first
%                   sample is used to calculate baseline stats).
%  filttype       - Type of filter to use (see buttfilt)
%  filtfreq       - Frequency range for filter (see buttfilt)
%  filtorder      - Order of filter (see buttfilt)
%  bufferMS       - Size of buffer to use when filtering (see buttfilt)
%  width          - Size of wavelets to use in power calculation
%                   (see getphasepow)
%  precision      - precision of the returned values; can be 'single'
%                   or 'double' (default)
%  absThresh      - absolute threshold: if voltage (relative to baseline)
%                   of an event exceeds this value, power for that event
%                   will be excluded (replaced with NaNs).
%  kthresh        - Kurtosis threshold: if kurtosis of the raw voltage 
%                   of any event exceeds this value, power for that event
%                   will be excluded (replaced with NaNs).
%  ztransform     - Logical specifying whether to z-transform the power
%  logtransform   - Logical specifying whether to log-transform the power
%  artWindow      - Two-element vector specifying what to exclude on events
%                   that contain a blink artifact:
%                     artWindow(1) - time in ms before the blink onset to begin
%                                    excluding
%                     artWindow(2) - time in ms after the blink onset to exclude
%                   Excluded time periods will be replaced with NaNs for that
%                   event for all channels.
%
%  See also create_pattern, sessVoltage.

warning('off', 'eeg_ana:patBinAllNaNs')

% input checks
if ~exist('pat','var')
  error('You must pass a pat object.')
elseif ~exist('events','var') || ~isstruct(events)
  error('You must pass an events structure.')
end
if ~exist('base_events','var') || isempty(base_events)
  base_events = events;
elseif ~isstruct(base_events)
  error('base_events must be a structure.')
end
if ~exist('bins','var')
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
                        'kthresh',         [],        ...
                        'ztransform',      true,     ...
                        'logtransform',    false,    ...
                        'artWindow',       500,      ...
                        'precision',       'single');

% initialize the pattern for this session
pattern = NaN(length(events), length(params.channels), ...
              length(pat.dim.time), length(pat.dim.freq), params.precision);

% load bad channel info for these events
if params.excludeBadChans
  [params.bad_chans, params.event_ind] = get_bad_chans({events.eegfile});
end

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
  power = getphasepow(events, channel, params.freqs, params.durationMS, params.offsetMS, p);

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
    % log transform
    power = log10(power);
  end
  
  % remove blink artifacts
  if ~isempty(params.artWindow)
    % get the final sample rate
    if ~isempty(params.downsample)
      final_rate = params.downsample;
    else
      final_rate = params.resampledRate;
    end

    % get time bins in MS for each element of time dim for artifact marking
    time_bins = make_bins(1000 / final_rate, params.offsetMS, ...
                          params.offsetMS + params.durationMS);
    
    % remove bad event-time points
    isart = markArtifacts(events, time_bins, params.artWindow);
    isart = repmat(isart, [1 1 size(power,3)]);
    power(isart) = NaN;
  end

  % remove events where this channel was labeled "bad"
  if params.excludeBadChans
    bad_events = mark_bad_chans(channel, params.bad_chans, params.event_ind);
    power(bad_events,:,:) = NaN;
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
