function samp = ms2samp(ms, samplerate, start_ms)
%MS2SAMP   Convert millisecond values to samples.
%
%  samp = ms2samp(ms, samplerate, start_ms)
%
%  INPUTS:
%          ms:  array of times in milliseconds.
%
%  samplerate:  samplerate in Hz.
%
%    start_ms:  start of the epoch in milliseconds. The returned
%               samples will be relative to this point.
%               Default is 0.
%
%  OUTPUTS:
%        samp:  array of times in samples from the start time.
%
%  EXAMPLES:
%   % translate a time after stimulus onset to samples
%   time_post_stim = 400;
%   samplerate = 500;
%   samp = ms2samp(time_post_stim, samplerate);
%
%   % translate a time that is given in experiment start time,
%   % rather than relative to some event in the experiment
%   time_from_start = 320000;
%   recording_start_time = 1500;
%   samp = ms2samp(time_from_start, samplerate, recording_start_time);

% input checks
if ~exist('ms', 'var')
  error('You must pass a value in milliseconds to be converted.')
elseif ~exist('samplerate', 'var')
  error('You must specify a sampling rate.')
end
if ~exist('start_ms', 'var')
  start_ms = 0;
end

elapsed_ms = ms - start_ms;
samp_per_ms = samplerate / 1000;

samp = ceil(elapsed_ms * samp_per_ms);

