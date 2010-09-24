function index = make_sample_index(eeg_offset, eeg_file)

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

