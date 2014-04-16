function [pattern, opt] = amp_pattern(events, channels, varargin)
%AMP_PATTERN   Create a pattern matrix of oscillatory power.
%
%  [pattern, params] = amp_pattern(events, channels, ...)
%
%  Calculate amplitude at a frequency band, using the Hilbert transform.
%
%  INPUTS:
%    events:  an events structure. Must have "eegfile" and "eegoffset"
%             fields.
%
%  channels:  vector of channel numbers to include in the pattern.
%
%  OUTPUTS:
%   pattern:  an [events X channel X time X frequency] matrix
%             containing amp values.
%
%    params:  structure of the final options used in creating the
%             pattern matrix.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   freqs           - REQUIRED - Frequency bands (in Hz) at which to
%                     calculate amplitude. Each row specifies the
%                     frequencies for a bandpass filter, in
%                     [start finish] form.
%   offsetMS        - time in milliseconds before each event to start
%                     the pattern. (-400)
%   durationMS      - duration in milliseconds of each epoch. (2400)
%   resampledrate   - samplerate (in Hz) to resample voltage before
%                     calculating amplitude. ([])
%   filttype        - type of filter to use (see buttfilt). ('stop')
%   filtfreq        - frequency range for filter (see buttfilt).
%                     ([58 62])
%   filtorder       - order of filter (see buttfilt). (4)
%   bufferMS        - size of buffer to use when filtering (see
%                     buttfilt). (1000)
%   boxcar_filt     - if true, returned amplitudes will be smoothed over
%                     time. (false)
%   boxcar_duration - width of the boxcar filter in ms. (100)
%   precision       - precision of the returned values. ('double')
%   verbose         - if true, more status will be printed. (false)
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

% options
def.freq_bands = [];
def.offsetMS = -400;
def.durationMS = 2400;
def.resampledRate = [];
def.filttype = 'stop';
def.filtfreq = [58 62];
def.filtorder = 4;
def.bufferMS = 1000;
def.boxcar_filt = false;
def.boxcar_duration = 100;
def.precision = 'double';
def.verbose = false;
[opt, run_opt] = propval(varargin, def);

def = struct;
def.dist = 0;
def.walltime = '00:30:00';
def.memory = '4G';
run_opt = propval(run_opt, def, 'strict', false);

if isempty(opt.freq_bands)
  error('You must specify frequencies at which to calculate power.')
end

if opt.verbose
  fprintf('parameters are:\n\n')
  disp(opt)
end

% figure out what the final samplerate will be
if ~isempty(opt.resampledRate)
  final_samplerate = opt.resampledRate;
else
  % set to the minimum samplerate
  final_samplerate = unique(get_events_samplerate(events));
  if length(final_samplerate) > 1
    final_samplerate = min(final_samplerate);
    opt.resampledRate = final_samplerate;
    fprintf(['Events contain multiple samplerates. ' ...
             'Resampling to %d Hz...\n'], opt.resampledRate)
  end
end

n_samps = ms2samp(opt.durationMS, final_samplerate);

% initialize the pattern matrix
n_events = length(events);
n_chans = length(channels);
n_freqs = size(opt.freq_bands, 1);

if run_opt.dist
  % run channels in parallel
  f_inputs = cell(1, n_chans);
  for i = 1:n_chans
    channel = channels(i);
    f_inputs{i} = {events channel opt};
  end
  
  job = submit_job(@get_chan_amp, 1, f_inputs, ...
                   'walltime', run_opt.walltime, ...
                   'memory', run_opt.memory, ...
                   'name', 'power_pattern');
  
  wait(job)
  
  % concatenate to get a [events X time X freq X chan] matrix
  pattern = fetchOutputs(job);
  pattern = cat(4, pattern{:});
  
  % reorder the dimensions
  pattern = permute(pattern, [1 4 2 3]);  
else
  fprintf('channels: ')
  pattern = NaN(n_events, n_chans, n_samps, n_freqs, opt.precision);
  for i = 1:n_chans
    % get the current channel number
    channel = channels(i);
    fprintf('%d ', channel);
    
    pattern(:,i,:,:) = get_chan_amp(events, channel, opt);
  end
  fprintf('\n')
end


function amp = get_chan_amp(events, channel, opt)

  % get amplitude based on Hilbert transform
  amp = amp_hilbert(events, channel, opt.freq_bands, opt.durationMS, ...
                    opt.offsetMS, ...
                    rmfield(opt, {'freq_bands' 'durationMS' ...
                                  'offsetMS' 'verbose'}));
    
  % change the order of dimensions to [events X time X frequency]
  amp = permute(amp, [1 3 2]);
  