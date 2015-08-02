function samplerate = get_events_samplerate(events)
%GET_EVENTS_SAMPLERATE   Get the samplerate(s) from an events structure.
%
%  samplerate = get_events_samplerate(events)
%
%  INPUTS:
%      events:  an events structure that has been aligned with EEG data.
%
%  OUTPUTS:
%  samplerate:  vector of samplerates of EEG data associated with the
%               events, one for each separate file.

% input checks
if ~exist('events', 'var') || ~isstruct(events)
  error('You must input an events structure.')
elseif ~isfield(events, 'eegfile')
  error('events must have an "eegfile" field.')
end

% get all unique EEG files
eegfiles = {events.eegfile};
eegfiles = unique(eegfiles(~cellfun(@isempty, eegfiles)));

% get samplerate for each file
f = @(x)GetRateAndFormat(fileparts(x));
samplerate = cellfun(f, eegfiles);
