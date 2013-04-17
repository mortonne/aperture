function bad_chans = reject_channels_regress(EEG, opt)
%REJECT_CHANNELS_REGRESS   Reject channels with poor contact.
%
%  Like the original channel rejection, but uses linear regression to
%  remove most of the variance from eye movements and blinks, so that
%  channels near the eye are not excluded unless they have poor
%  contact. The regression is just for detection purposes. Eye
%  movements will be dealt with more comprehensively through ICA at
%  a later step.
%
%  bad_chans = reject_channels_regress(EEG, opt)

eeg_chans = opt.eeg_chans;
ref_chan = opt.ref_chan;
eog_chans = opt.eog_chans;

% regress out contributions from the EOG channels. This won't be as
% good as ICA removal, since eye movements and blinks propogate
% over the scalp with different topographies, but it will be good
% enough to remove most of the variance of EOG
s(1) = warning('off', 'stats:glmfit:IllConditioned');
s(2) = warning('off', 'stats:glmfit:IterationLimit');
non_ref_chans = setdiff(eeg_chans, ref_chan);
for i = 1:length(non_ref_chans)
  for j = 1:size(EEG.data, 3)
    [b, dev, stats] = glmfit(EEG.data(eog_chans,:,j)', ...
                             EEG.data(non_ref_chans(i),:,j)', 'normal');
    EEG.data(non_ref_chans(i),:,j) = stats.resid;
    %EEG.data(non_ref_chans(i),:,:) = reshape(stats.resid, ...
    %                       [1 size(EEG.data, 2) size(EEG.data, 3)]);
  end
end
warning(s)

% treat all electrodes as one distribution
list_properties = channel_properties(EEG, eeg_chans, ref_chan);
lengths = min_z(list_properties, opt.rejection_options);

if isfield(opt, 'veog_chans')
  % use special rules for VEOG channels, since they are extremely
  % important for removing eye artifacts
  veog_chans = opt.veog_chans;
  non_veog_chans = setdiff(non_ref_chans, veog_chans);
  
  % use special criteria to determine which VEOG channels to include
  veog_include = select_veog(list_properties(:,2), ...
                             non_veog_chans, ...
                             veog_chans);
  
  % set so good VEOG channels will be included, even if they were
  % thrown out by the standard stats
  lengths(veog_include) = false;
end

% add user-specified bad channels
bad_chans = union(eeg_chans(logical(lengths)), opt.bad_channels);

% ref chan may appear bad, but we shouldn't interpolate it!
bad_chans = setdiff(bad_chans, ref_chan); 

if opt.exclude_EOG_chans
  bad_chans = setdiff(bad_chans, eog_chans);
end

