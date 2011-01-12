function [pattern, params] = voltage_pattern(events, channels, varargin)
%VOLTAGE_PATTERN   Load voltage values into a pattern matrix.
%
%  [pattern, params] = voltage_pattern(events, channels, ...)
%
%  INPUTS:
%    events:  an events structure. Must have "eegfile" and "eegoffset"
%             fields.
%
%  channels:  vector of channel numbers to include in the pattern.
%
%  OUTPUTS:
%   pattern:  [events X channels X time] matrix of voltage values.
%
%    params:  structure of the final options used in creating the
%             pattern matrix.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   offsetMS      - time in milliseconds before each event to start the
%                   pattern. (-200)
%   durationMS    - duration in milliseconds of each epoch. (2200)
%   relativeMS    - period in milliseconds to use for calculating the
%                   average to be subtracted for each event. ([-200 0])
%   resampledRate - samplerate (in Hz) to resample to. ([])
%   filttype      - type of filter to use (see buttfilt). ('low')
%   filtfreq      - frequency range for filter (see buttfilt). (40)
%   filtorder     - order of filter (see buttfilt). (4)
%   bufferMS      - size of bufferMS to use when filtering (see
%                   buttfilt). (1000)
%   precision     - precision of the returned values. ('double')
%   verbose       - if true, more status will be printed. (false)
%
%  See also create_voltage_pattern.

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

% options
defaults.offsetMS = -200;
defaults.durationMS = 2200;
defaults.relativeMS = [-200 0];
defaults.resampledRate = [];
defaults.filttype = 'low';
defaults.filtfreq = 40;
defaults.filtorder = 4;
defaults.bufferMS = 1000;
defaults.precision = 'double';
defaults.verbose = false;
[params, unused] = propval(varargin, defaults);

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
n_samps = ms2samp(params.durationMS, final_samplerate);

% initialize the pattern matrix
n_events = length(events);
n_chans = length(channels);
pattern = NaN(n_events, n_chans, n_samps, params.precision);

fprintf('channels: ')
for i=1:n_chans
  fprintf('%d ', channels(i))
  
  % load voltage for this channel
  pattern(:,i,:) = gete_ms(channels(i), ...
                           events, ...
                           params.durationMS, ...
                           params.offsetMS, ...
                           params.bufferMS, ...
                           params.filtfreq, ...
                           params.filttype, ...
                           params.filtorder, ...
                           params.resampledRate, ...
                           params.relativeMS);
end
fprintf('\n')

