function samples = make_sample_matrix(events, start, finish, ...
                                      samplerate_data, samplerate_pat)

% assuming that finish time is inclusive

index = make_sample_index([events.eegoffset], {events.eegfile});

n_events = length(events);

% time in samples relative to the onset sample
start_samp = ms2samp(start, samplerate_data);
finish_samp = ms2samp(finish, samplerate_data);

% add to make the samples matrix
step = ms2samp(1000 / samplerate_pat, samplerate_data);
event_samples = repmat(start_samp:step:finish_samp, n_events, 1);

duration = finish - start + 1000 / samplerate_pat;
n_pat_samps = ms2samp(duration, samplerate_pat);
samp_index = repmat(index', 1, n_pat_samps);
samples = samp_index + event_samples;

