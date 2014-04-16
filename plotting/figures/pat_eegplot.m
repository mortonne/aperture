function pat_eegplot(pat)
%PAT_EEGPLOT   Plot a voltage pattern in a scrolling viewer.
%
%  pat_eegplot(pat)

data = permute(get_mat(pat), [2 3 1]);
srate = get_pat_samplerate(pat);
eloc_file = 'HCGSN128.loc';
time = get_dim_vals(pat.dim, 'time');
limits = [time(1) time(end)];

eegplot(data, 'srate', srate, 'eloc_file', eloc_file, ...
        'limits', limits);
