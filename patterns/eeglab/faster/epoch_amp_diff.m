function amp_diffs = epoch_amp_diff(eeg, channels)
%EPOCH_AMP_DIFF   Max amplitude difference for each channel-epoch.
%
%  amp_diffs = epoch_amp_diff(eeg, channels)
%
%  INPUTS:
%        eeg:  EEGLAB dataset.
%
%   channels:  indices of channels to include.
%
%  OUTPUTS:
%  amp_diffs:  [channels X epochs] matrix of amplitude differences.

amp_diffs = permute(range(eeg.data(channels,:,:), 2), [1 3 2]);

