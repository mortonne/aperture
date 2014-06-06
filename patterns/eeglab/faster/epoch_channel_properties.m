function list_prop = epoch_channel_properties(EEG, eeg_chans, ref_chan)
%EPOCH_CHANNEL_PROPERTIES   Statistics on epoch-channels.
%
%  Calculates a number of statistics of individual channels and
%  epochs. Same as single_epoch_channel_properties, but can process
%  multiple epochs simultaneously. By vectorizing code, this
%  function runs much faster.
%
%  Each statistic is corrected for distance from the reference
%  electrode using quadratic regression.
%
%  list_prop = epoch_channel_properties(EEG, eeg_chans, ref_chan)

if nargin < 3
  ref_chan = [];
end

n_measures = 4;
list_prop = NaN(length(eeg_chans), n_measures, EEG.trials);

measure = 1;

% variance due to fast changes, relative to total variance
ssfast = sum(diff(EEG.data, [], 2).^2, 2);
sstot = sum((EEG.data - ...
             repmat(mean(EEG.data, 2), [1 EEG.pnts 1])).^2, 2);
list_prop(:,measure,:) = ssfast ./ sstot;
measure = measure + 1;

% variance
list_prop(:,measure,:) = var(EEG.data(eeg_chans,:,:), [], 2);
list_prop(isnan(list_prop(:,measure)),measure) = 0;
measure = measure + 1;

% total change
list_prop(:,measure,:) = range(EEG.data(eeg_chans,:,:), 2);
measure = measure + 1;

% deviation from channel mean
chan_mean = mean(EEG.data(eeg_chans,:), 2);
list_prop(:,measure,:) = abs(mean(EEG.data(eeg_chans,:,:), 2) - ...
                             repmat(chan_mean, [1 1 EEG.trials]));

if length(ref_chan) == 1
  % distance from the reference channel to each recording channel
  ref_ind = find(eeg_chans == ref_chan);
  pol_dist = distancematrix(EEG, eeg_chans);
  pol_dist = pol_dist(ref_ind, eeg_chans);
  
  % all stats are undefined at reference
  list_prop(ref_ind,:,:) = NaN;
  
  % use quadratic regression to correct each stat for distance
  for i = 1:size(list_prop, 2)
    for j = 1:size(list_prop, 3)
      list_prop(:,i,j) = correct_ref_dist(pol_dist, list_prop(:,i,j));
    end
  end
end

for i = 1:size(list_prop, 2)
  for j = 1:size(list_prop, 3)
    % set undefined stats to the median over the other channels
    list_prop(isnan(list_prop(:,i,j)),i,j) = nanmedian(list_prop(:,i,j));
  
    % subtract out the median of each property
    list_prop(:,i,j) = list_prop(:,i,j) - median(list_prop(:,i,j));
  end
end

