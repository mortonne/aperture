function events = loadEvents(filename, replace_eegfile, event_filter)
%LOADEVENTS - Load an events structure from a file.
%
% Use this function to load an events structure from a file and set
% it to a specified variable.  The .mat file must contain a
% variable named 'events'.
%
% FUNCTION:
%   events = loadEvents(filename)
%
% INPUT ARGS:
%   filename = 'events/events.mat';  % .mat file containing the events
%   replace_eegfile = {'/Users/lynne/FRdata','/data/eeg/scalp/fr/fr1'};
%
% OUTPUT ARGS:
%   events - The events structure from the file
%

load(filename)

% see if must process replace_eegfile
if exist('replace_eegfile','var') & ~isempty(replace_eegfile) & isfield(events,'eegfile')
  if length(replace_eegfile) == 1
    % loop and prepend eegfile entries
    for i = 1:length(events)
      if ~strcmp(events(i).eegfile,'')
        [dirname,basename] = fileparts(events(i).eegfile);
        events(i).eegfile = fullfile(replace_eegfile{1},basename);
      end
    end
  elseif length(replace_eegfile) == 2
    % loop and replace the eegfile entries
    for i = 1:length(events)
      for j = 1:size(replace_eegfile,1)
        events(i).eegfile = strrep(events(i).eegfile,replace_eegfile{j,1},replace_eegfile{j,2});
      end
    end
  else
    error('replace_eegfile must be a cell array of 1 or 2 items.');
  end
end

% see if filtering the struct before returning
if exist('event_filter', 'var') & ~isempty(event_filter)
  events = filterStruct(events, event_filter);
end