function [pulse_file, pulses] = ...
      mark_sync_pulses(fileroot, channel, flip, stat, thresh, doplot)
%MARK_SYNC_PULSES   Automatically find and record sync pulses.
%
%  pulse_file = mark_sync_pulses(fileroot, channel, flip, doplot)
%
%  INPUTS:
%  fileroot:  root of the EEG file(s) containing sync pulses.
%
%   channel:  channel number(s). If two channels specified, will look
%             for positive pulses in channel(1) - channel(2).
%
%      flip:  if true, will look for local minima rather than maxima.
%             Default is false.
%
%    doplot:  if true, the raw data and marked pulses will be plotted.
%             Default is false.
%
%  OUTPUTS:
%   A sync pulse file will be saved that ends in .sync.auto.txt, and saved in
%   the same directory as the input files.

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

if ~exist('flip', 'var')
  flip = false;
end
if ~exist('doplot', 'var')
  doplot = false;
end

% get monopolar or bipolar data with sync pulses
dat = load_chan(fileroot, channel);

% check for clipping
[clip_start_hi, clip_len_hi] = find_clipping(dat, max(dat));
[clip_start_lo, clip_len_lo] = find_clipping(-dat, -min(dat));

any_lo = ~isempty(clip_start_lo);
any_hi = ~isempty(clip_start_hi);
len_lo = mean(clip_len_lo(clip_start_lo));
len_hi = mean(clip_len_hi(clip_start_hi));

if any_hi && ~any_lo
  clip_start = clip_start_hi;
elseif any_lo && ~any_hi
  clip_start = clip_start_lo;
elseif (any_hi && any_lo) && (len_hi > len_lo)
  clip_start = clip_start_hi;
elseif (any_hi && any_lo) && (len_lo > len_hi)
  clip_start = clip_start_lo;
else
  clip_start = [];
end

%if ~isempty(clip_start) && length(clip_start) / length(dat) > .0001
if ~isempty(clip_start) && kurtosis(dat(abs(dat) < max(abs(dat)))) < 10
  % enough clips that the saturation was probably caused by sync
  % pulses. Take the start of the clipping as the sync pulse time
  pulses = clip_start;
else
  dat = [0 diff(dat)];

  samplerate = GetRateAndFormat(fileparts(fileroot));
  dat = buttfilt(dat, [.1 80], samplerate, 'bandpass', 4);

  % get the times of the pulses from the raw data
  %pulses = extract_pulses(dat, flip, stat, thresh, doplot);
  pulses = find_pulse_periods(dat, samplerate, ...
                              'select', 'percentile_thresh', ...
                              'percent_thresh', thresh);
end

fprintf('Found %d pulses in: %s\n', length(pulses), fileroot)

% set the file to write to
[pathstr, name, ext] = fileparts(fileroot);
if length(channel)==1
  filename = sprintf('%s.%03d.sync.auto.txt', name, channel);
else
  filename = sprintf('%s.%03d.%03d.sync.auto.txt', name, channel);
end
pulse_file = fullfile(pathstr, filename);

% write the pulses
fid = fopen(pulse_file, 'w+');
fprintf(fid, '%d\n', pulses);
fclose(fid);

function [pulses, y] = extract_pulses(dat, flip, stat, thresh, doplot)
  if flip
    dat = -dat;
  end

  switch stat
    case 'local_max'
      [x, y] = local_max(dat);
  
      pulse_inds = y >= prctile(y, thresh);
      pulses = x(pulse_inds);
      y = y(pulse_inds);
    case 'clip'
      % find times where contiguous samples are identical; get the
      % centers of those windows
      y = find_clipping(dat, 2);
      
      % exclude windows where dat does not have a high enough value
      y(dat < prctile(dat, thresh)) = 0;
      pulses = find(y);
  end
  
  if doplot
    clf
    hold on;
    plot(dat);
    plot(pulses,y,'rx');
    hold off;
    axis tight;
    xlabel('time (samples)');
    ylabel('\muV');
  end

function[pulses,y] = extract_pulses_old(dat)
  m = nanmean(dat);
  s = nanstd(dat);

  % flip sign if necessary to make the larger part of the pulses up
  % (assuming that the majority of the file is sync pulses)
  if m < 0
    dat = -dat;
  end

  % remove any high-amplitude artifacts (often found at the end of
  % the session, when sync channels are disconnected)
  bad_samp = dat < (m - s) | dat > (m + s*5);
  dat(bad_samp) = 0;

  %first approximation: local maxima
  [x,y] = local_max(dat);

  %{
  %only include sync pulses which were nearby in time
  ipi = diff(x); %ipi = inter-pulse interval
  good_inds = ipi <= prctile(ipi,10);

  %look for big breaks in pulses
  big_ipi_inds = (ipi > prctile(ipi,99.999));
  %}

  %pulse_inds = (y >= prctile(y,98)) & (y <= prctile(y,99));
  pulse_inds = (y >= prctile(y,99));
  %pulses = pulses(pulse_inds);
  pulses = x(pulse_inds);
  y = y(pulse_inds);

  %plot the pulses
  clf
  hold on;
  plot(dat);
  plot(pulses,y,'rx');
  hold off;
  axis tight;
  xlabel('time (samples)');
  ylabel('\muV');

