function bad_epochs = epoch_component_sep(EEG)
%EPOCH_COMPONENT_SEP   Identify epochs with poor component separation.
%
%  In most recording sessions, some epochs will violate the
%  assumptions of ICA, causing poor component separation on those
%  epochs. This function attempts to identify those epochs, so they
%  can be removed for another round of ICA (which will hopefully be
%  more successful).
%
%  bad_epochs = epoch_component_sep(EEG)

if ~isfield(EEG, 'icaact') || isempty(EEG.icaact)
  EEG.icaact = eeg_getica(EEG);
end

% (1) look for correlation increases during bad epochs. For some
% reason, this doesn't seem to distinguish the bad epochs, maybe
% because the metric ignores absolute variance? Maybe covariance might
% work better?

% n_comp = size(EEG.icaact, 1);
% r = NaN(EEG.trials, n_comp, n_comp);
% p = NaN(EEG.trials, n_comp, n_comp);
% for i = 1:EEG.trials
%   [r(i,:,:), p(i,:,:)] = corr(EEG.icaact(:,:,i)');
% end
% z = (r - repmat(median(r, 1), [size(r, 1) 1 1])) ./ ...
%     repmat(iqr(r, 1), [size(r, 1) 1 1]);
% inc = r > (repmat(median(r, 1), [size(r, 1) 1 1]) + ...
%       repmat(iqr(r, 1), [size(r, 1) 1 1]));

% (2) look for epochs accounting for a large amount of relative
% variance (compared to other epochs for that component), for many
% components. This got all the main problem epochs I identified
% manually, plus some others I hadn't looked at yet. Specificity is
% high, sensitivity is less known but probably good.
v = squeeze(var(EEG.icaact, 0, 2));
z = (v - repmat(median(v, 2), [1 size(v, 2)])) ./ ...
    repmat(iqr(v, 2), [1 size(v, 2)]);

m = median(z, 1);
thresh = median(m) + (3 * iqr(m));
bad_epochs = find(m > thresh);
