function EEG = eeg_faster_post_ica(EEG, bad_comp, eeg_chans, ref_chan)

% % add component information
% f = {'icaact' 'icawinv' 'icasphere' 'icaweights' 'icachansind' 'etc'};
% for i = 1:length(f)
%   EEG.(f{i}) = ica_info.(f{i});
% end

% reject components
EEG = pop_subcomp(EEG, bad_comp, 0);

% interpolate bad channels
chans_to_interp = setdiff(eeg_chans, [EEG.icachansind ref_chan]);
if ~isempty(chans_to_interp)
  EEG = eeg_interp(EEG, chans_to_interp, 'spherical');
end

% interpolate bad epoch-channels
EEG = eeg_interp_epoch(EEG, eeg_chans, ref_chan);

% average reference
EEG = pop_reref(EEG, [], 'keepref', 'on');

% interpolate epoch-channels again
EEG = eeg_interp_epoch(EEG, eeg_chans, []);

