function [ev, events] = cat_events(evs, ev_name, source, res_dir)
%CAT_EVENTS   Concatenate a set of events.
%
%  [ev, events] = cat_events(evs, ev_name, source, res_dir)
%
%  INPUTS:
%      evs:  a vector of ev objects.
%
%  ev_name:  string identifier for the new events.
%
%   source:  optional string that will set the 'source' field of the new
%            ev object.  Default: 'multiple'
%
%  res_dir:  directory where the new events structure will be saved.
%            Default is the parent directory of the first ev object's
%            file.
%
%  OUTPUTS:
%       ev:  ev object with metadata for the new concatenated events
%            structure.

% input checks
if ~exist('evs', 'var') || ~isstruct(evs)
  error('You must pass an array of ev objects.')
elseif ~isvector(evs)
  error('evs must be a vector.')
end
if ~exist('ev_name', 'var')
  ev_name = 'cat_events';
end
if ~exist('source', 'var')
  source = 'multiple';
end
if ~exist('res_dir', 'var')
  res_dir = get_ev_dir(evs(1));
end

% print status
evs_name = unique({evs.name});
if length(evs_name)==1
  fprintf('concatenating "%s" events...\n', evs_name{1})
else
  fprintf('concatenating events...\n')
end

% concatenate events
events = [];
for ev=evs
  fprintf('%s ', ev.source)
  events = [events get_mat(ev)];
end
fprintf('\n')

% create the new ev object
ev_file = fullfile(res_dir, objfilename('events', ev_name, source));
ev = init_ev(ev_name, 'source', source, 'file', ev_file);

% save the events
ev = set_mat(ev, events);

