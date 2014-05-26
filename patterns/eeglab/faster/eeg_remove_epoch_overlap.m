function eeg_cont = eeg_remove_epoch_overlap(eeg_seg)
%EEG_REMOVE_EPOCH_OVERLAP   Create a continous dataset from segmented data.
%
%  eeg_cont = eeg_remove_epoch_overlap(eeg_seg)
%
%  Take a segmented dataset with or without some overlap between
%  epochs, and create a continuous dataset. Only samples that are in
%  at least one of the epochs will be included. It is assumed that a
%  given sample (i.e., signal at a given time in the recording) will
%  have the same associated data regardless of which epoch is being
%  examined.
%
%  This function requires a field indicating the onset of each epoch
%  in samples, in the original recording. For epoch i, this
%  information is assumed to be in eeg_seg.epoch(i).eegoffset. If
%  there are multiple recording sessions, set the session number
%  in eeg_seg.epoch.session, so the eegoffset can be adjusted to
%  place all sessions on the same (arbitrary) timeline.
%
%  The original timing information is saved in eeg_cont.orig.
%
%  See also eeg_epoch2continuous; if there is no overlap between epochs,
%  use that function instead, since it is simpler and faster.

fprintf('Removing epoch overlap...\n')

events = eeg_seg.epoch;

if length(unique({events.eegfile})) > 1
  eegfile = {events.eegfile};
  ueegfile = unique(eegfile);
  
  % determine an adequate buffer so that epochs in different EEG
  % files are not assigned too close of eegoffsets
  time_range = NaN(1, length(ueegfile));
  time_max = NaN(1, length(ueegfile));
  for i = 1:length(ueegfile)
    ind = find(strcmp(eegfile, ueegfile{i}));
    time_max(i) = events(ind(end)).eegoffset;
    time_range(i) = time_max(i) - events(ind(1)).eegoffset;
  end
  buffer = max(time_range);
  
  for i = 2:length(ueegfile)
    ind = find(strcmp(eegfile, ueegfile{i}));
    
    c = num2cell([events(ind).eegoffset] + time_max(i-1) + buffer);
    [events(ind).eegoffset] = c{:};
  end
end

% start and end of each epoch in the original recording
epoch_offset = eeg_seg.xmin * eeg_seg.srate;
start_offset = [events.eegoffset] + epoch_offset;
finish_offset = start_offset + (eeg_seg.pnts - 1);

% find all samples that are included in at least one epoch
all_offsets = [];
for i = 1:length(start_offset)
  all_offsets = [all_offsets start_offset(i):finish_offset(i)];
end
all_offsets = unique(all_offsets);

% place the samples from each epoch; for samples in multiple
% epochs, the last epoch will take precedence (assuming this isn't
% an issue because assuming a given sample will have the same data
% regardless of which epoch we're looking at)
[n_chans, n_frames, n_epochs] = size(eeg_seg.data);
n_samples = length(all_offsets);

eeg_cont = rmfield(eeg_seg, 'data');
eeg_cont.data = NaN(n_chans, n_samples, 1, 'single');
new_start = NaN(1, n_epochs);
for i = 1:length(events)
  new_start(i) = find(all_offsets == start_offset(i));
  new_finish = find(all_offsets == finish_offset(i));
  eeg_cont.data(:,new_start(i):new_finish,:) = eeg_seg.data(:,:,i);
end
clear eeg_seg

% save original timing info
eeg_cont.orig.trials = eeg_cont.trials;
eeg_cont.orig.pnts = eeg_cont.pnts;
eeg_cont.orig.srate = eeg_cont.srate;
eeg_cont.orig.xmin = eeg_cont.xmin;
eeg_cont.orig.xmax = eeg_cont.xmax;
eeg_cont.orig.times = eeg_cont.times;
eeg_cont.orig.event = eeg_cont.event;
eeg_cont.orig.epoch = eeg_cont.epoch;

% change the metadata to match the new shape, so eeg_checkset
% doesn't reshape the data
eeg_cont.trials = 1;
eeg_cont.pnts = n_samples;
eeg_cont.srate = 1;
eeg_cont.xmin = 1;
eeg_cont.xmax = n_samples;
eeg_cont.times = 1:n_samples;
eeg_cont.epoch = eeg_cont.epoch(1);

% set events for each epoch, for visualization purposes
main_event_type = eeg_cont.epoch.type;
event = eeg_cont.event(strcmp({eeg_cont.event.type}, main_event_type));
[event.epoch] = deal(1);
c = num2cell(new_start);
[event.latency] = c{:};
eeg_cont.event = event;

% check field consistency
eeg_cont = eeg_checkset(eeg_cont);




