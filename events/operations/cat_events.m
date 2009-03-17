function [ev,events] = cat_events(evs,ev_name,res_dir)
%CAT_EVENTS   Concatenate a set of events.
%
%  [ev, events] = cat_events(evs, ev_name, res_dir)
%
%  INPUTS:
%      evs:  a vector of ev objects.
%
%  ev_name:  string identifier for the new events.
%
%  res_dir:  directory where the new events structure will
%            be saved.
%
%  OUTPUTS:
%       ev:  ev object with metadata for the new concatenated
%            events structure.

% input checks
if ~exist('evs','var')
  error('You must pass a vector of ev objects.')
end
if ~exist('ev_name','var')
  ev_name = 'cat_events';
end
if ~exist('res_dir','var')
  res_dir = fileparts(fileparts(evs(1).file));
end

% prepare the directory for the new events structure
ev_dir = fullfile(res_dir, 'events');
if ~exist(ev_dir)
  mkdir(ev_dir)
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
  events = [events load_events(ev)];
end
fprintf('\n')

% save the new events
ev_file = fullfile(ev_dir, sprintf('events_%s_multiple.mat', ev_name));
save(ev_file, 'events')

% create the new ev object
ev = init_ev(ev_name, 'multiple', ev_file, length(events));
