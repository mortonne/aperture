function bad_chans = reject_channels(EEG, opt)

eeg_chans = opt.eeg_chans;
ref_chan = opt.ref_chan;

if isfield(opt, 'fp_chans')
  % reject frontopolar and non-frontopolar electrodes separately
  fp_chans = opt.fp_chans;
  lengths = false(length(eeg_chans), 1);
  
  % stats for frontopolar electrodes
  fp_properties = channel_properties(EEG, fp_chans, ref_chan);
  lengths(fp_chans) = min_z(fp_properties, opt.rejection_options);
  
  % stats for posterior electrodes
  non_fp_chans = setdiff(eeg_chans, fp_chans);
  non_fp_properties = channel_properties(EEG, non_fp_chans, ...
                                         ref_chan);
  lengths(non_fp_chans) = min_z(non_fp_properties, ...
                                opt.rejection_options);
else
  % treat all electrodes as one distribution
  eeg_properties = channel_properties(EEG, eeg_chans, ref_chan);
  lengths = min_z(list_properties, opt.rejection_options);
end

if isfield(opt, 'veog_chans')
  % use special rules for VEOG channels, since they may
  % have much higher variance if there are many eye
  % movements, and are important for removing
  % eye artifacts
  veog_chans = opt.veog_chans;
  if exist('non_fp_chans', 'var')
    eeg_properties = NaN(length(eeg_chans), size(fp_properties, 2));
    eeg_properties(fp_chans,:) = fp_properties;
    eeg_properties(non_fp_chans,:) = non_fp_properties;
    
    % if non-FP chans are defined, use them for baseline stats
    non_veog_chans = non_fp_chans;
  else
    % if there are no FP chans defined, use all non-VEOG channels
    % for baseline stats
    non_veog_chans = setdiff(eeg_chans, veog_chans);
  end
  
  % use special criteria to determine which VEOG channels to include
  veog_include = select_veog(eeg_properties(:,2), ...
                             non_veog_chans, ...
                             veog_chans);
  
  % set so good VEOG channels will be included, even if they were
  % thrown out by the standard stats
  lengths(veog_include) = false;
end

% add user-specified bad channels
bad_chans = union(eeg_chans(logical(lengths)), opt.bad_channels);

% ref chan may appear bad, but we shouldn't interpolate it!
bad_chans = setdiff(bad_chans,ref_chan); 

