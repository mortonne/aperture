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
if ~exist('ev','var')
  error('You must pass an ev object.')
end

if isfield(ev,'mat')
  % already loaded; just grab it
  events = ev.mat;
  
  else
  % must load from file
  if ~exist(ev.file,'file')
    error('Events file %s not found.', ev.file)
  end
  
  % load the events structure
  s = load(ev.file);
  if ~isfield(s,'events')
    error('File %s does not contain a variable named events.')
  end
  events = s.events;
end
