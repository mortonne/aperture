function list_properties = component_properties(EEG,blink_chans,lpf_band)

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


list_properties = [];
%
if isempty(EEG.icaweights)
    fprintf('No ICA data.\n');
    return;
end

if ~exist('lpf_band','var') || length(lpf_band)~=2 || ~any(lpf_band)
    ignore_lpf=1;
else
    ignore_lpf=0;
end

delete_activations_after=0;
if ~isfield(EEG,'icaact') || isempty(EEG.icaact)
    delete_activations_after=1;
    EEG.icaact = eeg_getica(EEG);
end

if ~ignore_lpf
  for u = 1:size(EEG.icaact,1)
    [spectra(u,:) freqs] = pwelch(EEG.icaact(u,:),[],[],(EEG.srate),EEG.srate);
  end
  
  f_ind = find(freqs >= lpf_band(1),1):find(freqs <= lpf_band(2),1,'last');
end

% attempt to improve EMG comp-epoch detection by finding epochs with high
% EMG. Doesn't seem to help
%inc_chans = setdiff(1:EEG.nbchan, blink_chans);
%chan_gradient = squeeze(median(median(abs(diff(EEG.data(inc_chans,:,:), [], 2)), 2), 1));
%rej.measure = 1;
%rej.z = 2;
%lengths = min_z(chan_gradient, rej);
%emg_ind = find(lengths);

%chan_gradient = median(abs(diff(EEG.data(inc_chans,:), [], 2)), 1);

list_properties = zeros(size(EEG.icaact,1),5); %This 5 corresponds to number of measurements made.

for u=1:size(EEG.icaact,1)
    measure = 1;
    % TEMPORAL PROPERTIES

    % 1 Median gradient value, for high frequency stuff
    x = squeeze(EEG.icaact(u,:,:))';
    
    % median over time
    % m = median(abs(diff(x, [], 2)), 2);
    ssfast = sum(sum(diff(x, [], 2).^2, 2), 1);
    sstot = sum(sum((x - repmat(mean(x, 2), [1 size(x,2)])).^2, 2), 1);
    
    % filter to remove changes over the session due to impedance changes
    %mf = buttfilt(double(m), .01, 1, 'high', 4);
    
    % max over trials, to detect cases where EMG is only high for some
    % trials
    %list_properties(u,measure) = median(m);
    list_properties(u,measure) = ssfast / sstot;

    %comp_gradient = abs(diff(EEG.icaact(u,:), [], 2));
    %list_properties(u,measure) = corr(chan_gradient, comp_gradient);
    %list_properties(u,measure) = median(mean(abs(diff(x, [], 2)), 2));
    %list_properties(u,measure) = median(kurtosis(diff(x, [], 2),1,1));
    %list_properties(u,measure) = median(abs(diff(EEG.icaact(u,:))));
    measure = measure + 1;

    % 2 Mean slope around the LPF band (spectral)
    if ignore_lpf
        list_properties(u,measure) = 0;
    else
      %list_properties(u,measure) = mean(diff(10*log10(spectra(u,find(freqs>=lpf_band(1),1):find(freqs<=lpf_band(2),1,'last')))));
      x = log10(spectra(u, f_ind));
      p = polyfit(1:length(x), x, 1);
      list_properties(u,measure) = p(1);
      %list_properties(u,measure) = mean(diff(10*log10(spectra(u, f_ind))));
      %list_properties(u,measure) = mean(log10(spectra(u, f_ind)));
    end
    measure = measure + 1;

    % SPATIAL PROPERTIES

    % 3 Kurtosis of spatial map (if v peaky, i.e. one or two points high
    % and everywhere else low, then it's probably noise on a single
    % channel)
    list_properties(u,measure) = kurt(EEG.icawinv(:,u));
    measure = measure + 1;

    % OTHER PROPERTIES

    % 4 Hurst exponent
    list_properties(u,measure) = hurst_exponent(EEG.icaact(u,:));
    measure = measure + 1;

    % 10 Eyeblink correlations
    if exist('blink_chans','var') && ~isempty(blink_chans)
        rho = corr(EEG.icaact(u,:)', EEG.data(blink_chans,:)');
        list_properties(u,measure) = max([abs(rho) 0]);
        measure = measure + 1;
    end
end

for u = 1:size(list_properties,2)
    list_properties(isnan(list_properties(:,u)),u)=nanmedian(list_properties(:,u));
    list_properties(:,u) = list_properties(:,u) - median(list_properties(:,u));
end

if delete_activations_after
    EEG.icaact=[];
end