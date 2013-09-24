function [EEG, rej_epoch] = eeg_runica_adapt(EEG, eeg_chans, varargin)
%EEG_RUNICA_ADAPT   Run ICA iteratively, removing poorly separated epochs.
%
%  [EEG, rej_epoch] = eeg_runica_adapt(EEG, eeg_chans, ...)

% options
def.overlap = false;
def.max_iter = 10;
def.ica_type = 'binica';
def.ica_options = {'extended', 1};
opt = propval(varargin, def);

success = false;
iter = 0;
rej_epoch = {};
while iter < opt.max_iter
  if opt.overlap
    % convert overlapping epochs to continuous
    EEG = eeg_remove_epoch_overlap(EEG);
  end
  
  % run ICA on all included epochs
  EEG = pop_runica(EEG, 'chanind', eeg_chans, 'icatype', opt.ica_type, ...
                   'options', {opt.ica_options});
  
  if opt.overlap
    % convert back to original segments
    EEG = eeg_epoch_overlap(EEG);
  end
  
  % check for epochs with poor separation
  bad_epochs = epoch_component_sep(EEG);
  rej_epoch = [rej_epoch {bad_epochs}];
  
  if isempty(bad_epochs)
    % good separation for all epochs
    success = true;
    break
  else
    % remove poorly separated epochs and try again
    exclude = false(1, EEG.trials);
    exclude(bad_epochs) = true;
    EEG = pop_rejepoch(EEG, exclude, 0);
  end
end
