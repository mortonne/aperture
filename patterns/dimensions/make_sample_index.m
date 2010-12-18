function index = make_sample_index(eeg_offset, eeg_file)
%MAKE_SAMPLE_INDEX   Make an index that is unique for a set of samples.
%
%  Takes eeg_offset, which is the sample of the start of each event in
%  samples relative to the start of the recording and eeg_file, which
%  gives the recording, and returns an offset measure which is unique
%  across all recordings and has enough padding to allow for events form
%  separate recordings not overlapping.
%
%  index = make_sample_index(eeg_offset, eeg_file)
%
%  INPUTS:
%  eeg_offset:  vector of length events, containing the start of each
%               event in samples from the start of the recording.
%
%    eeg_file:  path to the file containing the recording for each
%               event.
%
%  OUTPUTS:
%       index:  vector with one element for each event containing a
%               unique samples measure.  No longer indicates time from
%               the start of the recording, but relative times are
%               preserved (with the exception of times between
%               recordings, which are assumed to be unimportant)

buffer = range(eeg_offset);
ufiles = unique(eeg_file);
for i = 1:length(ufiles)
  match = strcmp(eeg_file, ufiles{i});

  % add a buffer
  if i > 1
    eeg_offset(match) = eeg_offset(match) + prev_max + buffer;
  end
  prev_max = eeg_offset(max(find(match)));
end
index = eeg_offset;

