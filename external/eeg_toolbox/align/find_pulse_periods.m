function pulses = find_pulse_periods(dat, samplerate, varargin)
%FIND_PULSE_PERIODS   Find sync pulses in EEG data.
%
%  pulses = find_pulse_periods(dat, samplerate, ...)
%
%  INPUTS:
%         dat:  vector of EEG data.
%
%  samplerate:  rate at which the data were sampled, in Hz.
%
%  OUTPUTS:
%      pulses:  time (in samples) of located sync pulses.
%
%  OPTIONS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   spike_freq
%   pulse_freq
%   session_freq
%   baseline
%   session_thresh
%   session_duration
%   plot_pulses
%   select
%   pulse_thresh
%   percent_thresh
%   direction_thresh

% options
def.spike_freq = 25;
def.pulse_freq = 1;
def.session_freq = 0.01;
def.baseline = [0 60];
def.session_thresh = 2;
def.session_duration = 60;
def.plot_pulses = false;
def.select = 'percentile_thresh';
def.pulse_thresh = 4000;
def.percent_thresh = 90;
def.direction_thresh = 90;
opt = propval(varargin, def);

% get the upper and lower envelopes of the data
[uenv, lenv] = envelope(dat);

% find candidate times for sync pulses
thresh = prctile(abs(dat), opt.direction_thresh);
[upow, uind] = env_periods(uenv, samplerate, thresh, opt);
[lpow, lind] = env_periods(-lenv, samplerate, thresh, opt);

% choose between upper and lower envelopes based on pulse power
% during the candidate times
if upow >= lpow
  % spikes are positive; choose periods based on the upper envelope
  ind = uind;
  pulse_dat = dat(ind);
else
  % spikes are negative
  ind = lind;
  dat = -dat;
  pulse_dat = dat(ind);
end

% find candidate pulses
[pulses, y] = local_max(pulse_dat);

switch opt.select
  case 'expected'
    % get the pulses with the highest peaks, getting enough to match
    % the approximate number of expected pulses
    [~, sort_ind] = sort(y, 2, 'descend');
    n_pulses = opt.session_duration * 60 * opt.pulse_freq * 2;
    pulses = pulses(sort_ind(1:n_pulses));
  case 'percentile_thresh'
    pulses = pulses(pulse_dat(pulses) >= ...
                    prctile(pulse_dat, opt.percent_thresh));
  case 'thresh'
    % remove pulses below a given threshold
    pulses = pulses(pulse_dat(pulses) >= opt.pulse_thresh);
end

% translate back to the original indices
pulses = sort(ind(pulses));

% filter to get at most one pulse for each period
pulses = filter_pulses(pulses, dat(pulses), samplerate, opt);

if opt.plot_pulses
  if length(pulses) > 2000
    fprintf('Too many pulses to plot completely.\n')
    clf
    plot(dat, '-k')
    hold on
    plot(pulses(1:1000), dat(pulses(1:1000)), 'rx')
  else
    clf
    plot(dat, '-k')
    hold on
    plot(pulses, dat(pulses), 'rx')
  end
end


function [pow, ind] = env_periods(x_env, samplerate, thresh, opt)

  % first, calculate power over time at the spike frequency; this
  % should identify times where pulses are occuring (as well as
  % artifacts at that frequency)
  [~, spike_pow] = multiphasevec(opt.spike_freq, x_env, samplerate, 6);

  % get the power of the spike timecourse at the pulse frequency;
  % this should identify times where there are pulses
  [~, pulse_pow] = multiphasevec(opt.pulse_freq, spike_pow, samplerate, 6);

  % smooth the estimate of pulse times
  pulse_smooth = buttfilt(pulse_pow, opt.session_freq, samplerate, ...
                          'low', 1);
  
  % determine the baseline
  baseline_start = opt.baseline(1) * samplerate + 1;
  baseline_finish = opt.baseline(2) * samplerate;
  baseline_samp = baseline_start:baseline_finish;
  
  % calculate pulse power, relative to the baseline period
  pulse_m = mean(pulse_smooth(baseline_samp));
  pulse_s = std(pulse_smooth(baseline_samp));
  pulse_z = (pulse_smooth - pulse_m) / pulse_s;
  
  % if spike power at the pulse frequency is sufficiently greater than
  % the baseline, assume that this is a period with pulses
  ind = find(pulse_z >= opt.session_thresh);
  %pow = mean(pulse_pow(ind));
  %pow = nnz(abs(x_env(ind)) >= thresh) / length(ind);
  %pow = mean(pulse_smooth);
  %pow = length(ind);
  pow = mean(spike_pow(local_max(x_env)));

function pulses_filt = filter_pulses(pulses, pulse_dat, samplerate, opt)

  % get the number of pulses in each period (allowing for jitter)
  pulse_period_samp = (opt.pulse_freq * .7) * samplerate;
  edges = 0:pulse_period_samp:max(pulses);
  [n, bin] = histc(pulses, edges);

  % find the periods where there is only one identified pulse
  good_bins = find(n > 0);

  % get the corresponding pulse times
  pulses_filt = NaN(1, length(good_bins));
  pulses_dat_filt = NaN(1, length(good_bins));
  for i = 1:length(good_bins)
    bin_pulses = pulses(bin == good_bins(i));
    if length(bin_pulses) > 1
      % if there is more than one spike in this bin, choose the one with the
      % highest voltage
      bin_dat = pulse_dat(bin == good_bins(i));
      [max_dat, max_ind] = max(bin_dat);
      bin_pulses = bin_pulses(max_ind);
      pulses_dat_filt(i) = max_dat;
    else
      pulses_dat_filt(i) = pulse_dat(bin == good_bins(i));
    end
    pulses_filt(i) = bin_pulses;
  end
  
  % too_close = find(diff(pulses_filt) < pulse_period_samp);
  % pulses_filt2 = [];
  % for i = 1:length(pulses_filt)
  %   if any(i == too_close)
  %     if pulses_dat_filt(i) > pulses_dat_filt(i + 1)
  %       pulses_filt2 = [pulses_filt2 pulses_filt(i)];
  %     end
  %   else
  %     pulses_filt2 = [pulses_filt2 pulses_filt(i)];
  %   end
  % end
  