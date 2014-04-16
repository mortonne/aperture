function [pattern, opt] = comod_pattern(events, channels, varargin)
%COMOD_PATTERN   Calculate modulation index for multiple events and channels.
%
%  [pattern, opt] = comod_pattern(events, channels, ...)

% options
def.fp = [];
def.fa = [];
def.offsetMS = -400;
def.durationMS = 2400;
def.precision = 'double';
def.bufferMS = 1000;
def.filttype = 'stop';
def.filtfreq = [58 62];
def.filtorder = 4;
def.filtbuffer = 1000;
opt = propval(varargin, def);

if isempty(opt.fp) || isempty(opt.fa)
  error('You must specify frequency bands')
end

n_fp = size(opt.fp, 1);
n_fa = size(opt.fa, 1);
n_events = length(events);
n_chans = length(channels);
samplerate = GetRateAndFormat(events(1));
pattern = NaN(n_events, n_chans, n_fp, n_fa, opt.precision);
duration = opt.durationMS + (opt.bufferMS * 2);
offset = opt.offsetMS - opt.bufferMS;
for i = 1:length(events)
  fprintf('%d ', i)
  for j = 1:length(channels)
    x_raw = gete_ms(channels(j), events(i), duration, ...
                    offset, opt.filtbuffer, opt.filtfreq, ...
                    opt.filttype, opt.filtorder);
    pattern(i,j,:,:) = comodulogram(x_raw, opt.fp, opt.fa, ...
                                    samplerate, opt.bufferMS)';
  end
end
fprintf('\n')

