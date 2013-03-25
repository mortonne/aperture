function eeg_seg = eeg_epoch_overlap(eeg_cont)
%EEG_EPOCH_OVERLAP   Convert overlapping epoch data back to epochs.
%
%  eeg_seg = eeg_epoch_overlap(eeg_cont)
%
%  For a continous dataset created by eeg_remove_epoch_overlap, this
%  function will move back to the original overlapping epochs.

orig = eeg_cont.orig;

% re-segment the data
eeg_seg = rmfield(eeg_cont, {'data' 'orig'});
eeg_seg.data = NaN(eeg_cont.nbchan, orig.pnts, orig.trials);
for i = 1:length(eeg_cont.event)
  start_ind = eeg_cont.event(i).latency;
  finish_ind = start_ind + (orig.pnts - 1);
  eeg_seg.data(:,:,i) = eeg_cont.data(:,start_ind:finish_ind);
end

% move the metadata back to what it was originally
eeg_seg.trials = orig.trials;
eeg_seg.pnts = orig.pnts;
eeg_seg.srate = orig.srate;
eeg_seg.xmin = orig.xmin;
eeg_seg.xmax = orig.xmax;
eeg_seg.times = orig.times;
eeg_seg.event = orig.event;
eeg_seg.epoch = orig.epoch;

% check field consistency
eeg_seg = eeg_checkset(eeg_seg);


