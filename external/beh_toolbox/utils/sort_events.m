function [sorted, index] = sort_events(events, times)
%SORT_EVENTS   Sort an events structure to match experimental order.
%
%  [sorted, index] = sort_events(events, times)
%
%  INPUTS:
%   events:  an events structure.
%
%    times:  name of a field containing times for each event, or a
%            vector of times corresponding to each event.
%            Default: 'mstime'
%
%  OUTPUTS:
%   sorted:  the events structure, sorted.
%
%    index:  index used to sort the events.

% input checks
if nargin < 1
  error('You must pass an events structure.')
elseif ~isstruct(events)
  error('events must be a structure.')
end
if nargin < 2
  times = 'mstime';
elseif ~(ischar(times) || (isnumeric(times) && isvector(times)))
  error('times must be a string or a numeric vector.')
end

% get experiment times
if ischar(times)
  times = [events.(times)];
end

% sort the times
[y, index] = sort(times);

% apply to events
sorted = events(index);

