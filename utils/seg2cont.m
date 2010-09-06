function [new_pattern, pat_size] = seg2cont(pattern, pat_size)

%make pattern eventsXtimeXchan
pattern = permute(pattern, [1 3 2]);

%unravel pattern so columns are channels and rows go from E1T1 to
%E2T1 to E(end-1)Tend to EendTend
new_pattern = reshape(pattern, size(pattern,1)*size(pattern,2), ...
                        size(pattern,3));



