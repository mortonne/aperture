function [new_pattern, pat_size] = seg2cont(pattern)

[n_events, n_chans, n_samps] = size(pattern);

%make pattern eventsXtimeXchan
pattern = permute(pattern, [1 3 2]);
%pattern = permute(pattern, [3 1 2]);

%unravel pattern so columns are channels and rows go from E1T1 to
%E2T1 to E(end-1)Tend to EendTend
new_pattern = reshape(pattern, n_events * n_samps, n_chans);

% now if there are n events and m samples:
%% E1T1 E1T2 ... E1Tm E2T1 E2T2 ... E2Tm ... EnTm
%new_pattern = reshape(pattern, n_events * n_samps, n_chans);



