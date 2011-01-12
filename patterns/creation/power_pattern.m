function [pattern, params] = power_pattern(events, channels, varargin)
%POWER_PATTERN   Create a pattern matrix of oscillatory power.
%
%  [pattern, params] = power_pattern(events, channels, ...)
%
%  Calculate oscillatory power using Morlet wavelets for all events in
%  an events structure.
%
%  INPUTS:
%    events:  an events structure. Must have "eegfile" and "eegoffset"
%             fields.
%
%  channels:  vector of channel numbers to include in the pattern.
%
%  OUTPUTS:
%   pattern:  an [events X channel X time X frequency] matrix
%             containing power values.
%
%    params:  structure of the final options used in creating the
%             pattern matrix.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   freqs         - REQUIRED - Frequencies (in Hz) at which to
%                   calculate power.
%   offsetMS      - time in milliseconds before each event to start the
%                   pattern. (-400)
%   durationMS    - duration in milliseconds of each epoch. (2400)
%   resampledRate - samplerate (in Hz) to resample voltage before
%                   calculating power. ([])
%   downsample    - samplerate (in Hz) to downsample oscillatory
%                   power. ([])
%   filttype      - type of filter to use (see buttfilt). ('stop')
%   filtfreq      - frequency range for filter (see buttfilt).
%                   ([58 62])
%   filtorder     - order of filter (see buttfilt). (4)
%   bufferMS      - size of buffer to use when filtering (see
%                   buttfilt). (1000)
%   width         - width (in wavenumbers) of the Morlet wavelets to
%                   use for calculating oscillatory power. (6)
%   absThresh     - absolute threshold: if voltage (relative to
%                   baseline) of an event exceeds this value, power for
%                   that event will be excluded (replaced with NaNs).
%                   ([])
%   kthresh       - kurtosis threshold: if kurtosis of the raw voltage 
%                   of any event exceeds this value, power for that
%                   event will be excluded (replaced with NaNs). ([])
%   logtransform  - logical; if true, power will be log-transformed.
%                   (true)
%   precision     - precision of the returned values. ('double')
%   verbose       - if true, more status will be printed. (false)
%
%  See also create_power_pattern.

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% input checks
if ~exist('events', 'var') || ~isstruct(events)
  error('You must pass an events structure.')
elseif ~exist('channels', 'var') || ~isnumeric(channels)
  error('You must specify channels at which to calculate voltage.')
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
defaults.verbose = false;
[params, unused] = propval(varargin, defaults);

if isempty(params.freqs)
  error('You must specify frequencies at which to calculate power.')
end

if params.verbose
  fprintf('parameters are:\n\n')
  disp(params)
end

% figure out what the final samplerate will be
if ~isempty(params.downsample)
  final_samplerate = params.downsample;
elseif ~isempty(params.resampledRate)
  final_samplerate = params.resampledRate;
else
  % set to the minimum samplerate
  final_samplerate = unique(get_events_samplerate(events));
  if length(final_samplerate) > 1
    final_samplerate = min(final_samplerate);
    params.resampledRate = final_samplerate;
    fprintf(['Events contain multiple samplerates. ' ...
             'Resampling to %d Hz...\n'], params.resampledRate)
  end
end
n_samps = ms2samp(params.durationMS, final_samplerate);

% initialize the pattern matrix
n_events = length(events);
n_chans = length(channels);
n_freqs = length(params.freqs);
pattern = NaN(n_events, n_chans, n_samps, n_freqs, params.precision);

% translate param names for getphasepow
params.absthresh = params.absThresh;
params.resampledrate = params.resampledRate;
params = rmfield(params, {'absThresh', 'resampledRate'});

fprintf('channels: ')
for i=1:n_chans
  % get the current channel number
  channel = channels(i);
  fprintf('%d ', channel);

  % using version in eeg_toolbox/branches/unstable...
  % calculate power from raw voltage for a set of frequencies
  power = getphasepow(events, channel, params.freqs, params.durationMS, ...
                      params.offsetMS, params, params.verbose);
  
  % change the order of dimensions to [events X time X frequency]
  power = permute(power, [1 3 2]);
  
  % log transform if desired
  if params.logtransform
    % if any values are exactly 0, make them eps
    power(power==0) = eps(0);
    power = log10(power);
  end
  
  % calculate power and add to the pattern
  pattern(:,i,:,:) = power;
end
fprintf('\n')

