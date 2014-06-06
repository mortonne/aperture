function EEG = eeg_faster_post_ica(EEG, bad_comp, eeg_chans, ref_chan, ...
                                   varargin)

% reject components
EEG = pop_subcomp(EEG, bad_comp, 0);

% interpolate bad channels
chans_to_interp = setdiff(eeg_chans, [EEG.icachansind ref_chan]);
if ~isempty(chans_to_interp)
  EEG = eeg_interp(EEG, chans_to_interp, 'spherical');
end

% interpolate bad epoch-channels
n_epochs_orig = EEG.trials;
[EEG, rej_epoch_chan, rej_epoch1] = eeg_interp_epoch(EEG, eeg_chans, ...
                                                  ref_chan, varargin{:});

% average reference
EEG = pop_reref(EEG, [], 'keepref', 'on');

% interpolate epoch-channels again
[EEG, rej_epoch_chan, rej_epoch2] = eeg_interp_epoch(EEG, eeg_chans, ...
                                                  [], varargin{:});

n_epochs_rej = length(rej_epoch1) + length(rej_epoch2);
fprintf('%d/%d (%.f%%) of trials rejected.\n', ...
        n_epochs_rej, n_epochs_orig, (n_epochs_rej/n_epochs_orig) * 100)
