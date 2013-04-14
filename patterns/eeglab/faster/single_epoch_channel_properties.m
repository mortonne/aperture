function list_properties = single_epoch_channel_properties(EEG, ...
                                        epoch_num, eeg_chans, ref_chan)
%SINGLE_EPOCH_CHANNEL_PROPERTIES   Stats on an epoch-channel.
%
%  list_properties = single_epoch_channel_properties(EEG, epoch_num,
%                                                    eeg_chans, ref_chan)
%
%  INPUTS:
%        EEG:  EEGLAB dataset struct.
%
%  epoch_num:  index of the epoch to examine.
%
%  eeg_chans:  array of indices of electrodes measuring EEG activity.
%
%   ref_chan:  index of the reference channel (set to [] or omit if
%              average reference).
%
%  OUTPUTS:
%  list_properties:  [channels X measures] matrix of channel statistics.

if nargin < 4
  ref_chan = [];
end

if ~isstruct(EEG)
  newdata = EEG;
  clear EEG;
  EEG.data = newdata;
  clear newdata;
end

measure = 1;

% 1 Median diff value
x = EEG.data(eeg_chans,:,epoch_num);
ssfast = sum(diff(x, [], 2).^2, 2);
sstot = sum((x - repmat(mean(x, 2), [1 size(x, 2)])).^2, 2);
list_properties(:,measure) = ssfast ./ sstot;
%list_properties(:,measure) = median(abs(diff(EEG.data(eeg_chans,:,epoch_num),[],2)),2);
measure = measure + 1;

% 2 Variance of the channels
list_properties(:,measure) = var(EEG.data(eeg_chans,:,epoch_num),[],2);
list_properties(isnan(list_properties(:,measure)),measure) = 0;
measure = measure + 1;

% 3 Max difference of each channel
list_properties(:,measure) = range(EEG.data(eeg_chans,:,epoch_num), 2);
measure = measure + 1;

% 4 Deviation from channel mean
list_properties(:,measure) = abs(mean(EEG.data(eeg_chans,:,epoch_num),2)-mean(EEG.data(eeg_chans,:),2));
measure = measure + 1;

if length(ref_chan) == 1
  % distance from the reference channel to each recording channel
  pol_dist = distancematrix(EEG, eeg_chans);
  pol_dist = pol_dist(ref_chan, eeg_chans);
  
  % all stats are undefined at reference
  list_properties(ref_chan,:) = NaN;
  
  % use quadratic regression to correct each stat for distance
  for i = 1:size(list_properties, 2)
    list_properties(:,i) = correct_ref_dist(pol_dist, list_properties(:,i));
  end
end

for u = 1:size(list_properties, 2)
  % set undefined stats to the mean over the other channels
  list_properties(isnan(list_properties(:,u)),u) = ...
      nanmedian(list_properties(:,u));
  
  % subtract out the median of each property
  list_properties(:,u) = list_properties(:,u) - median(list_properties(:,u));
end