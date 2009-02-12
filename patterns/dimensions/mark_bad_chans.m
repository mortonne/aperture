function isbad = mark_bad_chans(chan_numbers, bad_chans, event_ind)
%MARK_BAD_CHANS   Mark events and channels that have bad signal.
%
%  isbad = mark_bad_chans(chan_numbers, bad_chans, event_ind)
%
%  INPUTS:
%  chan_numbers:  a vector of integers specifying which channels
%                 to include in the output matrix.
%
%     bad_chans:  a cell array giving information about which channels
%                 are "bad" for a set of EEG files. Each cell must have
%                 a vector of integers specifying bad channels.
%
%     event_ind:  a vector with one integer for each event. Each element
%                 should give the index of that element in the bad_chans
%                 cell array.
%
%  OUTPUTS:
%         isbad:  a logical [events X channels] matrix that is true for
%                 each bad event/channel.
%
%  EXAMPLE:
%   % get bad channel information for an events structure
%   [bad_chans, event_ind] = get_bad_chans({events.eegfile});
%
%   % combine channel and event info to make a bad channels logical array
%   isbad = mark_bad_chans(1:129, bad_chans, event_ind);
%
%   % throw out bad data in a events X channels matrix of EEG data
%   eeg_data(isbad) = NaN;

% the returned logical includes all events and channels regardless of "badness"
isbad = false(length(event_ind), length(chan_numbers));

for i=1:length(bad_chans)
  % of the chans specified, which are bad?
  chans_to_mark = intersect(chan_numbers, bad_chans{i});

  % get the events that correspond to this set of bad channels
  events_to_mark = event_ind==i;

  % mark the badness
  isbad(events_to_mark, chans_to_mark) = true;
end
