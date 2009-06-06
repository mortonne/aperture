function [ev,events] = cat_events(evs,ev_name,res_dir,label)
%CAT_EVENTS   Concatenate a set of events.
%
%  [ev, events] = cat_events(evs, ev_name, res_dir, label)
%
%  INPUTS:
%      evs:  a vector of ev objects.
%
%  ev_name:  string identifier for the new events.
%
%  res_dir:  directory where the new events structure will
%            be saved.
%
%    label:  optional string indicating a suffix to use for the
%            filename of the concatenated events structure.
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
  res_dir = get_ev_dir(evs(1), 'events');
end
if ~exist('label','var')
  label = 'multiple';
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
ev_file = fullfile(res_dir, sprintf('%s_%s.mat', ev_name, label));
save(ev_file, 'events')

% create the new ev object
ev = init_ev(ev_name, 'multiple', ev_file, length(events));
