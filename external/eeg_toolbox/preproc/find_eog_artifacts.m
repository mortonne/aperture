function [artifacts,eeg] = find_eog_artifacts(events,channels,offsetMS,durationMS,params)
%FIND_EOG_ARTIFACTS   Mark eye artifacts.
%
%  [artifacts,eeg] = find_eog_artifacts(events,channels,offsetMS,durationMS,params)
%
%  Run findBlinks on segmented data. A buffer can be added around each
%  epoch before blink detection to prevent edge effects.
%
%  INPUTS:
%      events:  events structure with all events to search for blinks.
%
%    channels:  an array of one or two channel numbers; if two channels
%               are provided, blink detection will be run on the difference.
%
%    offsetMS:  time in milliseconds before each event to get voltage.
%
%  durationMS:  duration of each event in milliseconds.
%
%      params:  structure containing options for loading EEG signal and
%               detecting blinks; see below for options.
%
%  OUTPUTS:
%   artifacts:  [events X samples] logical array, where samples containing
%               artifacts are marked as true.
%
%         eeg:  [events X samples] array of voltage values that were used 
%               to find artifacts, not including the buffer.
%
%  PARAMS:
%  bufferMS      - buffer to add around each event before blink detection
%                  to avoid any edge effects. Default: 1000
%  filtfreq      - 
%  filttype      - 
%  filtorder     - 
%  resampledrate - 
%  relativeMS    - 
%  blinkthresh   - threshold in uV for the fast running average. See
%                  findBlinks.
%  blinkopt      - starting values for the running averages; see findBlinks.

% input checks
if ~exist('events','var') || ~isstruct(events)
  error('You must pass an events structure.')
  elseif ~exist('channels','var') || ~isnumeric(channels)
  error('You must pass a channel number.')
  elseif ~exist('offsetMS','var') || ~isnumeric(offsetMS)
  error('You must pass a scalar indicating the offset.')  
  elseif ~exist('durationMS','var') || ~isnumeric(durationMS)
  error('You must pass a scalar indicating the duration.')
end
if ~exist('params','var')
  params = struct();
end

% set default parameters
params = structDefaults(params, ...
                        'bufferMS',      1000,      ...
                        'filtfreq',      [],        ...
                        'filttype',      'stop',    ...
                        'filtorder',     1,         ...
                        'resampledrate', [],        ...
                        'relativeMS',    [],        ...
                        'blinkthresh',   100,       ...
                        'blinkopt',      [.5, .5, .975, .025]);

% get final the sampling rate for the raw voltage
if ~isempty(params.resampledrate)
  samplerate = round(params.resampledrate);
else
  samplerate = GetRateAndFormat(events(1));  
end

% load the eeg, including the buffer
eeg_durationMS = durationMS + 2*params.bufferMS;
eeg_offsetMS = offsetMS - params.bufferMS;
params.eeg_bufferMS = 0;
params.samplerate = samplerate;

chanstr = sprintf('%d ', channels);
fprintf('Searching for eye artifacts with: threshold %guV, channels %s...\n', ...
         params.blinkthresh, chanstr);

if length(channels)==2
  eeg1 = load_eeg(events,channels(1),eeg_durationMS,eeg_offsetMS,params);
  eeg2 = load_eeg(events,channels(2),eeg_durationMS,eeg_offsetMS,params);
  eeg = eeg1 - eeg2;
  clear eeg1 eeg2
else
  eeg = load_eeg(events,channels,eeg_durationMS,eeg_offsetMS,params);
end

% detect artifacts
duration = ms2samp(durationMS, samplerate);
buffer = ms2samp(params.bufferMS, samplerate);

artifacts = false(length(events), duration);
for i=1:size(eeg,1)
  event_artifacts = findBlinks(eeg(i,:), params.blinkthresh, params.blinkopt);
  artifacts(i,:) = event_artifacts(buffer+1:end-buffer);
end

% remove the buffer from EEG data
eeg = eeg(:,buffer+1:end-buffer);

function eeg = load_eeg(events,channel,durationMS,offsetMS,params)
  %LOAD_EEG   Temporary wrapper for gete_ms to give it a more convenient
  %           calling signature.
  %
  %  eeg = load_eeg(events,channel,durationMS,offsetMS,params)
  %
  %  This is how gete_ms will work if and when I feel like breaking some
  %  existing eeg_toolbox functions.
  
  eeg = gete_ms(channel, ...
                events, ...
                durationMS, ...
                offsetMS, ...
                params.bufferMS, ...
                params.filtfreq, ...
                params.filttype, ...
                params.filtorder, ...
                params.samplerate, ...
                params.relativeMS);
%endfunction
