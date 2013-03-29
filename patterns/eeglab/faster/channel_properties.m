function list_properties = channel_properties(EEG, eeg_chans, ref_chan)
%CHANNEL_PROPERTIES   Stats on channels for rejection.
%
%  list_properties = channel_properties(EEG, eeg_chans, ref_chan)

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

%% notes for running on segmented data
% Just using raw channels is a bad idea for an EGI setup with
% impedance checks with crazy voltage recordings. Also, signal
% during breaks is often very erratic, so it would increase noise
% in the analysis if it were included. Want to reject channels
% based on the actual data we're using in the analysis.
%
% This seems to only be an issue for the Hurst exponent measure,
% since it is a temporal measure which will be sensitive to the
% breaks between different epochs. So that needs to be calculated
% within the epochs (preferably not too short), then take the
% median (the distributions I've seen are highly skewed).

if ~isstruct(EEG)
  newdata=EEG;
  clear EEG;
  EEG.data=newdata;
  clear newdata;
end

measure = 1;

if ~isempty(ref_chan) && length(ref_chan) == 1
  % get channel indices sorted by distance from the reference channel
  pol_dist = distancematrix(EEG, eeg_chans);
  
  % NWM: changed below to use correct_ref_dist
  pol_dist = pol_dist(ref_chan, eeg_chans);
  %[s_pol_dist, dist_inds] = sort(pol_dist(ref_chan, eeg_chans));
  %[s_inds, idist_inds] = sort(dist_inds);
end

% TEMPORAL PROPERTIES

% (1) mean correlation between each channel and all other channels

% ignore zeroed channels (ie reference channels) to avoid NaN problems
ignore = [];
datacorr = EEG.data;
for u = eeg_chans
  if max(EEG.data(u,:)) == 0 && min(EEG.data(u,:)) == 0
    ignore = [ignore u];
  end
end

% calculate correlations
calc_indices = setdiff(eeg_chans, ignore);
ignore_indices = intersect(eeg_chans, ignore);
corrs = abs(corrcoef(EEG.data(calc_indices,:)'));
mcorrs = zeros(size(eeg_chans));
for u = 1:length(calc_indices)
  mcorrs(calc_indices(u)) = mean(corrs(u,:));
end
mcorrs(ignore_indices) = mean(mcorrs(calc_indices));

% quadratic correction for distance from reference electrode
if ~isempty(ref_chan) && length(ref_chan) == 1
  % NWM: changed to use correct_ref_dist. Also stopped sorting output by
  % distance from ref, which seems to be a bug. Changed below also
  list_properties(:,measure) = correct_ref_dist(pol_dist, mcorrs);

  %p = polyfit(s_pol_dist, mcorrs(dist_inds), 2);
  %fitcurve = polyval(p, s_pol_dist);
  %corrected = mcorrs(dist_inds) - fitcurve(idist_inds);
  %list_properties(:,measure) = corrected;
else
  % NWM: commented code below looks like a bug, which could cause
  % rejection of the wrong channels. Should keep same sorting as
  % input, not sort by distance from ref
  list_properties(:,measure) = mcorrs;
  %list_properties(:,measure) = mcorrs(dist_inds);
end
measure = measure + 1;

% (2) variance of the channels
vars = var(EEG.data(eeg_chans,:)');
vars(~isfinite(vars)) = mean(vars(isfinite(vars)));

% quadratic correction for distance from reference electrode
if ~isempty(ref_chan) && length(ref_chan) == 1
  % NWM: changed to use correct_ref_dist
  list_properties(:,measure) = correct_ref_dist(pol_dist, vars);
  
  %p = polyfit(s_pol_dist, vars(dist_inds), 2);
  %fitcurve = polyval(p, s_pol_dist);
  %corrected = vars - fitcurve(idist_inds);
  %list_properties(:,measure) = corrected;
else
  list_properties(:,measure) = vars;
end
measure = measure + 1;

% (3) Hurst exponent
for u = 1:length(eeg_chans)
  if size(EEG.data, 3) > 1
    hurst_epoch = NaN(1, size(EEG.data, 3));
    for i = 1:size(EEG.data, 3)
      hurst_epoch(i) = hurst_exponent(EEG.data(eeg_chans(u),:,i));
    end
    list_properties(u,measure) = median(hurst_epoch);
  else
    list_properties(u,measure) = hurst_exponent(EEG.data(eeg_chans(u),:));
  end
end

% deal with remaining NaNs; subtract out the median
for u = 1:size(list_properties, 2)
  list_properties(isnan(list_properties(:,u)),u) = ...
      nanmean(list_properties(:,u));
  list_properties(:,u) = list_properties(:,u) - median(list_properties(:,u));
end