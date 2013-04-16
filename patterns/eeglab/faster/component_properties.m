function [list_properties, prop_type] = component_properties(EEG, blink_chans, ...
                                                lpf_band, emg_chans)

% Copyright (C) 2010 Hugh Nolan, Robert Whelan and Richard Reilly, Trinity College Dublin,
% Ireland
% nolanhu@tcd.ie, robert.whelan@tcd.ie
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

if nargin < 4
  emg_chans = [];
  if nargin < 3
    lpf_band = [];
    if nargin < 3
      blink_chans = [];
    end
  end
end

list_properties = [];

if isempty(EEG.icaweights)
  fprintf('No ICA data.\n');
  return
end

if ~exist('lpf_band', 'var') || length(lpf_band) ~= 2 || ~any(lpf_band)
  ignore_lpf = true;
else
  ignore_lpf = false;
end

if ~isfield(EEG,'icaact') || isempty(EEG.icaact)
  EEG.icaact = eeg_getica(EEG);
end

if ~ignore_lpf
  % calculate the spectrum for each component
  for u = 1:size(EEG.icaact, 1)
    [spectra(u,:), freqs] = pwelch(EEG.icaact(u,:), [], [], EEG.srate, ...
                                   EEG.srate);
  end
  f_ind = find(freqs >= lpf_band(1),1):find(freqs <= lpf_band(2),1,'last');
end

n_corr_prop = length(blink_chans) + length(emg_chans);
n_prop = 4 + n_corr_prop;
prop_type = [1 2 3 4 repmat(5, [1 n_corr_prop])];
list_properties = NaN(size(EEG.icaact, 1), n_prop);
for u = 1:size(EEG.icaact, 1)
  measure = 1;
  
  % TEMPORAL PROPERTIES

  % 1 Median gradient value, for high frequency stuff
  comp = squeeze(EEG.icaact(u,:,:))';
    
  % fast changes divided by overall squared error over time
  ssfast = sum(sum(diff(comp, [], 2).^2, 2), 1);
  sstot = sum(sum((comp - repmat(mean(comp, 2), [1 size(comp,2)])).^2, 2), 1);
  list_properties(:, measure) = ssfast / sstot;
  measure = measure + 1;

  % 2 Mean slope around the LPF band (spectral)
  if ignore_lpf
    list_properties(u, measure) = 0;
  else
    x = log10(spectra(u, f_ind));
    p = polyfit(1:length(x), x, 1);
    list_properties(u, measure) = p(1);
  end
  measure = measure + 1;

  % SPATIAL PROPERTIES

  % 3 Kurtosis of spatial map (if v peaky, i.e. one or two points high
  % and everywhere else low, then it's probably noise on a single
  % channel)
  list_properties(u, measure) = kurt(EEG.icawinv(:,u));
  measure = measure + 1;

  % OTHER PROPERTIES

  % 4 Hurst exponent
  list_properties(u, measure) = hurst_exponent(EEG.icaact(u,:));
  measure = measure + 1;

  % 5a Eyeblink correlations
  if ~isempty(blink_chans)
    rho = corr(EEG.icaact(u,:)', EEG.data(blink_chans,:)');
    for i = 1:length(blink_chans)
      list_properties(u, measure) = max([abs(rho(i)) 0]);
      measure = measure + 1;
    end
  end
  
  % 5b EMG correlations
  if ~isempty(emg_chans)
    comp = comp';
    rho = corr(comp(:), EEG.data(emg_chans,:)');
    for i = 1:length(emg_chans)
      list_properties(u, measure) = max([abs(rho(i)) 0]);
      measure = measure + 1;
    end
  end
end

for u = 1:size(list_properties, 2)
  list_properties(isnan(list_properties(:,u)),u) = nanmedian(list_properties(:,u));
  list_properties(:,u) = list_properties(:,u) - median(list_properties(:,u));
end

