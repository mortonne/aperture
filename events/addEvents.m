function eeg = addEvents(eeg, eventsFile)
%eeg = addEvents(eeg, eventsFile)

for s=1:length(eeg.subj)
  events = [];
  for n=1:length(eeg.subj(s).sess)
    sess_events = load(fullfile(eeg.subj(s).sess(n).dir, eventsFile));
    events = concat(events(:), sess_events(:))';
  end
  
  
end
