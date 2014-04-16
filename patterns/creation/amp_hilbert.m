function amp = amp_hilbert(events, channel, freqs, duration, offset, ...
                           varargin)
%AMP_HILBERT   Amplitude of filtered EEG over time.
%
%  amp = amp_hilbert(events, channel, freqs, duration, offset, ...)

samplerate = GetRateAndFormat(events(1));

% options
def.bufferMS = 1000;
def.filtfreq = [58 62];
def.filttype = 'stop';
def.filtorder = 4;
def.resampledRate = samplerate;
def.precision = 'double';
def.boxcar_filt = false;
def.boxcar_duration = 100;
opt = propval(varargin, def);

if ~opt.boxcar_filt
  opt.boxcar_duration = 0;
end

%% load unfiltered EEG

eeg_duration = duration + (2 * opt.bufferMS) + (opt.boxcar_duration);
eeg_offset = offset - opt.bufferMS;
eeg_buffer = 0;
eeg = gete_ms(channel, events, eeg_duration, eeg_offset, eeg_buffer, ...
              opt.filtfreq, opt.filttype, opt.filtorder, opt.resampledRate);

%% calculate amplitude

% convert the durations to samples
duration_samp = ms2samp(duration + opt.boxcar_duration, opt.resampledRate);
buffer_samp = ms2samp(opt.bufferMS, opt.resampledRate);
total_samp = ms2samp(eeg_duration, opt.resampledRate);

n_events = length(events);
n_freqs = size(freqs, 1);
amp = NaN(n_events, n_freqs, duration_samp, opt.precision);
for i = 1:n_events
  for j = 1:n_freqs
    % filter in the band of interest
    x_filt = ft_preproc_bandpassfilter(eeg(i,:), samplerate, freqs(j,:), ...
                                       [], 'fir');
    
    % remove buffer
    x_filt = x_filt((buffer_samp + 1):(total_samp - buffer_samp));
    
    amp(i,j,:) = abs(hilbert(x_filt));
  end
end

if opt.boxcar_filt
  % smooth using a moving average
  boxcar_samp = ms2samp(opt.boxcar_duration, opt.resampledRate);
  amp = boxcar_filter(amp, boxcar_samp, 3);
  boxcar_half = round(boxcar_samp / 2);
  amp = amp(:,:,(boxcar_half+1):end-boxcar_half);
end

