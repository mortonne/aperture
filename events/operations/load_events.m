function events = load_events(ev)
%LOAD_EVENTS   Load events from an ev object.
%
%  events = load_events(ev)
%
%  If the events structure is saved to disk, ev.file will be loaded.
%  If events is stored in the "mat" field, it will be retrieved from
%  that.
%
%  INPUTS:
%       ev:  an ev object.
%
%  OUTPUTS:
%   events:  an events structure.

% input checks
if ~exist('ev','var') || ~isstruct(ev)
  error('You must pass an ev object.')
elseif length(ev)>1
  error('ev must be of length 1.')
elseif ~any(isfield(ev, {'file', 'mat'}))
  error('The events object must have a "file" or "mat" field.')
end

if isfield(ev,'mat') && ~isempty(ev.mat)
  % already loaded; just grab it
  events = ev.mat;
else
  % must load from file
  if ~exist(ev.file, 'file')
    error('Events file not found: %s', ev.file)
  end
  
  % load the events structure
  s = load(ev.file, 'events');
  events = s.events;
end

% check the events structure
if isempty(events)
  warning('loading an empty events structure.')
elseif ~isstruct(events)
  error('events must be a structure.')
elseif ~isvector(events)
  error('events must be a vector')
end

% make sure we are returning a row vector
if size(events,1)>1
  events = reshape(events, 1, length(events));
end
