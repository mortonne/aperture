function samples = make_sample_matrix(events, start, finish, ...
                                      samplerate_data, samplerate_pat)
%MAKE_SAMPLE_MATRIX   Create unique labels for each sample in events.
%
%  samples = make_sample_matrix(events, start, finish, samplerate_data,
%                                                        samplerate_pat)
%
%  INPUTS:
%           events:  an events structure.
%
%            start:  start of each event in milliseconds.
%
%           finish:  end of each event in milliseconds.
%
%  samplerate_data:  samplerate of the raw data referenced by
%                    events.eegfile.
%
%   samplerate_pat:  samplerate of the pattern; will be used for
%                    creation of the samples matrix.
%
%  OUTPUTS:
%          samples:  [events X samples] matrix with a label that
%                    identifies unique samples. That is, if
%                    samples[i,j] == samples[n,m], those positions in
%                    the pattern matrix are taken from the same offset
%                    in the EEG file.

% assuming that finish time is inclusive
index = make_sample_index([events.eegoffset], {events.eegfile});

% time in samples relative to the onset sample
start_samp = ms2samp(start, samplerate_data);
finish_samp = ms2samp(finish, samplerate_data);

% add to make the samples matrix
step = ms2samp(1000 / samplerate_pat, samplerate_data);
n_events = length(events);
event_samples = repmat(start_samp:step:finish_samp, n_events, 1);

duration = finish - start + 1000 / samplerate_pat;
n_pat_samps = ms2samp(duration, samplerate_pat);
samp_index = repmat(index', 1, n_pat_samps);
samples = samp_index + event_samples;

