function new_pattern = cont2seg(pattern, pat_size)

%reravel pattern back to its almost original size (eventsXtimeXchan)
new_pattern = reshape(pattern, pat_size(1), pat_size(3), pat_size(2));

%new_pattern = reshape(pattern, pat_size(3), pat_size(1), pat_size(2));

%make pattern eventsXchanXtime
new_pattern = permute(new_pattern, [1 3 2]);
%new_pattern = permute(new_pattern, [2 3 1]);

