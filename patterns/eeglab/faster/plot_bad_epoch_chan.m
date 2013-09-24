function plot_bad_epoch_chan(EEG, bad_epoch_chan)
%PLOT_BAD_EPOCH_CHAN   Plot rejected channel-epochs.
%
%  plot_bad_epoch_chan(EEG, bad_epoch_chan)

d2 = EEG.data;
for i = 1:length(bad_epoch_chan)
  good = setdiff(1:EEG.nbchan, bad_epoch_chan{i});
  d2(good,:,i) = NaN;
end

eegplot(EEG.data, 'srate', EEG.srate, 'eloc_file', EEG.chanlocs, ...
        'limits', [EEG.times(1) EEG.times(end)], 'data2', d2);

