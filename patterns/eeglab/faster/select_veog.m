function veog_include = select_veog(chan_var, eeg_chans, veog_chans)
%SELECT_VEOG   Determine which VEOG channels should be included.
%
%  veog_include = select_veog(chan_var, eeg_chans, veog_chans)

% make sure variance values are positive (median has been subtracted)
if any(chan_var < 0)
  chan_var = chan_var + abs(min(chan_var));
end

% variance relative to non-VEOG channels
non_veog_chans = setdiff(eeg_chans, veog_chans);
z_veog_var = (chan_var(veog_chans) - mean(chan_var(non_veog_chans))) ./ ...
    std(chan_var(non_veog_chans));

if any(z_veog_var < -3)
  % there are flatlining channels
  veog_chans = veog_chans(z_veog_var >= -3);
  if isempty(veog_chans)
    % cannot use either if their variance is extremely low
    veog_include = [];
    return
  elseif length(veog_chans) < (length(z_veog_var) / 2)
    % if there are fewer than half of the channels remaining,
    % include them regardless of their other statistics
    veog_include = veog_chans;
    return
  end
end

% get the ratio of variance of each channel to the other VEOG channels
veog_rel_var = NaN(1, length(veog_chans));
for i = 1:length(veog_chans)
  other_veog = setdiff(veog_chans, veog_chans(i));
  veog_rel_var(i) = chan_var(veog_chans(i)) / mean(chan_var(other_veog));
end

% exclude flailing channels with very high variance relative to the
% other VEOG channels
veog_include = veog_chans(veog_rel_var < 3);

