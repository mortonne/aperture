function saveEvents(events,filename)
%SAVEEVENTS - Save an events structure to a file
%
% Saves an events structure to a file.
%
% FUNCTION:
%   saveEvents(events,filename)
%
% INPUT ARGS:
%   events = rec_events;  % Events structure to save
%   filename = 'events/rec_events.mat'; % file to save to
%
%

%
% 2005/10/21 - PBS: Reverted to save in current version.
% 2004/07/03 - PBS: Saves events in version 6 format.
% 2003/12/8 - PBS: Fixed that events was not a string.
%

save(filename,'events');


