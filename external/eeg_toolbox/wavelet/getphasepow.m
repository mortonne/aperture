function [varargout] = getphasepow(events,channel,freqs,durationMS,offsetMS,params,verbose)
%GETPHASEPOW   Calculate wavelet phase and power for a set of events.
%
%  [pow, phase] = getphasepow(events, channel, freqs, durationMS, offsetMS, 
%                             params, verbose)
%
%  Calculate wavelet phase and power as a function of time and frequency for a
%  single electrode.
%
%  INPUTS:
%      events:  standard events structure. Must have eegfile and eegoffset 
%               fields.
%     channel:  number of the channel to calculate phase and power for.
%       freqs:  array of frequencies (in Hz).
%  durationMS:  duration in ms of the period to calculate phase and power.
%               Power will be calculated for the period of:
%               offset to (offset + duration)
%               for each event.
%    offsetMS:  time in ms before the beginning of each event to begin
%               calculating phase and power.
%      params:  structure that specifies additional options for calculating
%               power. See below.
%     verbose:  boolean. If true, more output will be printed. 
%
%  OUTPUTS:
%       pow:    an [events X frequency X time] matrix of power values.
%     phase:    an [events X frequency X time] matrix of phase values.
%
%  PARAMS:
%   width         - width of the Morlet wavelets used (default: 6)
%   bufferMS      - time in ms to use as a buffer on both sides of
%                   each epoch to prevent edge artifacts (default: 1000)
%   filtfreq      - frequency to filter before phase and power are
%                   calculated (see buttfilt)
%   filttype      - string indicating type of filter
%   filtorder     - order of the filter
%   resampledrate - rate (in Hz) to resample to before calculating phase
%                   and power
%   downsample    - rate (in Hz) to decimate to after calculating phase
%                   and power
%   precision     - precision of the returned values; can be 'single'
%                   or 'double' (default)
%   absthresh     - voltage threshold to apply to raw voltage. Events
%                   with a voltage value crossing this threshold will
%                   be thrown out (filled with NaNs in the returned
%                   matrices)
%   kthresh       - kurtosis threshold to apply to raw voltage.
%
%  EXAMPLES:
%   % calculate power for all events, channel 23, and a range of
%   % frequencies from 2 to 100 Hz
%   events = loadEvents(file);
%   channel = 23;
%   freqs = 2.^(1:(1/8):6.7);
%   duration = 2200;
%   offset = -200;
%   pow = getphasepow(events, channel, freqs, duration, offset);

% Changes:
% 4/16/09 - NWM - Complete rewrite of implementation, interface, and
%                 documentation.
% 1/6/06 - PBS - Added decimation of phase.
% 9/15/05 - PBS - Added downsampling via decimate following power calculation.
% 9/15/05 - PBS - Return the logical index of the events not thrown out
%                 with the kurtosis thresh.
% 7/8/05 - MvV - Return the index of the events thrown out with the
%                kurtosis threshold if desired
% 1/18/05 - PBS - Ignore the buffer when applying kurtosis.
%                 Changed round to fix when determine durations.
%                 No longer gets double buffer when buffer is specified.
% 10/30/04 - PBS - Added a kthresh option for filtering events with
%                  high kurtosis.
% 8/25/04 - PBS - Made it an option to create phase and pow
%                 matrixes as singles.
% 3/18/04 - PBS - Switched to gete_ms and added ability to resample
% 11/20 josh 1. changed filtfreq to [] rather than 0. 2. Got rid of the 'single()' function calls that were
% forcing us to return single rather than doubles.  it was pretty
% annoying. per was there a good reason for this function to return
% singles?

% input checks
if ~exist('events','var') || ~isstruct(events)
  error('You must pass an events structure.')
  elseif ~exist('channel','var') || ~isnumeric(channel)
  error('You must pass a channel number.')
  elseif ~exist('freqs','var') || ~isnumeric(freqs)
  error('You must pass an array of frequencies.')
  elseif ~exist('durationMS','var') || ~isnumeric(durationMS)
  error('You must pass a scalar indicating the duration.')
  elseif ~exist('offsetMS','var') || ~isnumeric(offsetMS)
  error('You must pass a scalar indicating the offset.')
end
if ~exist('params','var')
  params = struct();
end
if ~exist('verbose','var')
  verbose = false;
end

% user-defined defaults
def_width = eeganalparams('width');
if isempty(def_width)
  def_width = 5;
end

% set default parameters
params = structDefaults(params, ...
                        'width',         def_width, ...
                        'bufferMS',      1000,      ...
                        'filtfreq',      [],        ...
                        'filttype',      'stop',    ...
                        'filtorder',     [],         ...
                        'resampledrate', [],        ...
                        'relativeMS',    [],        ...
                        'downsample',    [],        ...
                        'precision',     'double',  ...
                        'absthresh',     [],        ...
                        'kthresh',       []         );
bufferMS = params.bufferMS;

% get final the sampling rate for the raw voltage
samplerate = GetRateAndFormat(events(1));
if ~isempty(params.resampledrate)
  samplerate = round(params.resampledrate);
end

% load the eeg, including the buffer
eeg_durationMS = durationMS + 2*bufferMS;
eeg_offsetMS = offsetMS - bufferMS;
eeg_bufferMS = 0;
eeg = gete_ms(channel, ...
              events, ...
              eeg_durationMS, ...
              eeg_offsetMS, ...
              eeg_bufferMS, ...
              params.filtfreq, ...
              params.filttype, ...
              params.filtorder, ...
              samplerate,       ...
              params.relativeMS);

% convert the durations to samples
duration = ms2samp(durationMS, samplerate);
buffer = ms2samp(bufferMS, samplerate);

if verbose
  fprintf('calculating power for %d events...\n', length(events))
end

% make a mask to mark bad events to be removed later
if ~isempty(params.kthresh) || ~isempty(params.absthresh)
  mask = false(length(events),1);
end

% mark bad events
if ~isempty(params.kthresh)
  k_mask = kurtosis(eeg(:,buffer+1:end-buffer),1,2) > params.kthresh;
  mask = mask | k_mask;
  if verbose
    fprintf('throwing out %d events with kurtosis greater than %d.\n', sum(k_mask), params.kthresh)
  end
end
if ~isempty(params.absthresh)
  abs_mask = max(abs(eeg(:,buffer+1:end-buffer)),[],2) > params.absthresh;
  mask = mask | abs_mask;
  if verbose
    fprintf('throwing out %d events with abs. value greater than %d.\n', sum(abs_mask), params.absthresh)
  end
end

% initialize the matrices that will hold power / phase,
% without the buffer
% output_size = {length(events), length(freqs), duration};
% pow = zeros(output_size{:}, params.precision);
% if nargout==2
%   phase = zeros(output_size{:}, params.precision);
% end

% version using multiphasevec2, which calculated only one epoch at
% a time:
% for i=1:size(eeg,1)
%   % get power and phase for this event
%   [event_phase,event_power] = multiphasevec2(freqs, eeg(i,:), samplerate, params.width);
%   % remove the buffer and place in the larger matrix
%   pow(i,:,:) = event_power(:, buffer+1:end-buffer);
%   if nargout==2
%     phase(i,:,:) = event_phase(:, buffer+1:end-buffer);
%   end
% end

% new version using multiphasevec3:
[phase, pow] = multiphasevec3(freqs, eeg, samplerate, params.width, ...
                              params.precision);

% remove the buffer
pow = pow(:,:,buffer+1:end-buffer);

if nargout == 1
  clear phase
else
  phase = phase(:,:,buffer+1:end-buffer);
end

% decimate phase/power
if ~isempty(params.downsample)
  % set the downsampled duration
  dmate = round(samplerate/params.downsample);
  dsDur = ceil(size(pow,3)/dmate);

  % Must log transform power before decimating
  pow(pow==0) = eps;
  pow = log10(pow);
  
  % initialize
  full_pow = pow;
  pow = zeros(size(pow,1), size(pow,2), dsDur, params.precision);
  if nargout==2
    full_phase = phase;
    phase = zeros(size(pow,1), size(pow,2), dsDur, params.precision);
  end

  % loop and decimate
  for e = 1:size(pow,1)
    for f = 1:size(pow,2)
      pow(e,f,:) = decimate(double(full_pow(e,f,:)), dmate);
      if nargout==2
        % decimate the unwraped phase, then wrap it back
        phase(e,f,:) = mod(decimate(double(unwrap(full_phase(e,f,:))),dmate)+pi,2*pi)-pi;
      end
    end
  end

  % convert back to no-log
  pow = 10.^pow;
end

% remove bad events
if exist('mask','var') && any(mask(:))
  pow(mask,:,:) = NaN;
  if nargout==2
    phase(mask,:,:) = NaN;
  end
end

if nargout==2
  varargout = {pow, phase};
  else
  varargout = {pow};
end
