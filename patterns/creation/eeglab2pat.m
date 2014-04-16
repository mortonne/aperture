function pat = eeglab2pat(eeg)
%EEGLAB2PAT   Import data from EEGLAB.
%
%  pat = eeglab2pat(eeg)

% metadata
pat_name = eeg.setname;
pat_file = '';
subj_id = eeg.subject;

% dimensions
events = convert_events(eeg.epoch);
chan = convert_chans(eeg.chanlocs);
time = init_time(eeg.times);
freq = init_freq();

% initialize the information struct
pat = init_pat(pat_name, pat_file, eeg.subject, struct, ...
               events, chan, time, freq);

% set the data matrix. Need to convert from [channels X time X events]
% to [events X channels X time]
pat = set_mat(pat, permute(eeg.data, [3 1 2]), 'ws');


function events = convert_events(events)

  % find auto-generated event fields, which correspond to events
  % within an epoch (these are not represented in the pattern
  % format)
  f = fieldnames(events);
  strip = false(1, length(f));
  for i = 1:length(f)
    if length(f{i}) >= 5 && strcmp(f{i}(1:5), 'event')
      strip(i) = true;
    end
  end
  events = rmfield(events, f(strip));
  
function chans = convert_chans(chanlocs)

  % rename the labels field, add default channel numbers
  labels = {chanlocs.labels};
  number = num2cell(1:length(chanlocs));
  chans = rmfield(chanlocs, 'labels');
  [chans.number] = number{:};
  [chans.label] = labels{:};
  