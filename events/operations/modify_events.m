function ev = modify_events(ev, f, f_inputs, varargin)
%MODIFY_EVENTS   Modify an existing events structure.
%
%  ev = modify_events(ev, f, f_inputs, ...)
%
%  INPUTS:
%        ev:  an events object.
%
%         f:  handle to a function of the form:
%              events = f(events, ...)
%
%  f_inputs:  cell array of additional inputs to f.
%
%  OUTPUTS:
%        ev:  a modified events object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_filter - string for filterStruct to choose a subset of events
%                  to pass to the function. The result will be merged
%                  with all events. Any overlapping elements in the old
%                  structure will be replaced with their equivalents
%                  (based on the "eegfile" and "eegoffset" fields) in
%                  the new structure. ('')
%   save_mat     - if true, and input mats are saved on disk, modified
%                  mats will be saved to disk. If false, the modified
%                  mats will be stored in the workspace, and can
%                  subsequently be moved to disk using move_obj_to_hd.
%                  This option is useful if you want to make a quick
%                  change without modifying a saved pattern. (true)
%   overwrite    - if true, existing events on disk will be overwritten.
%                  (false)
%   save_as      - string identifier to name the modified events. If
%                  empty, the name will not change. ('')
%   res_dir      - directory in which to save the modified events.
%                  Default is a directory named ev_name on the same
%                  level as the input pat.

% input checks
if ~exist('ev', 'var') || ~isstruct(ev)
  error('You must pass an events object.')
elseif isempty(ev)
  error('The input ev object is empty.')
end
if ~isfield(ev, 'modified')
  ev.modified = false;
end
if ~exist('f', 'var') || ~isa(f, 'function_handle')
  error('You must pass a function handle.')
end
if ~exist('f_inputs', 'var')
  f_inputs = {};
end

% set default params
defaults.event_filter = '';
defaults.save_mat = true;
defaults.overwrite = false;
defaults.save_as = '';
defaults.res_dir = '';
params = propval(varargin, defaults, 'strict', false);

fprintf('modifying "%s" events...', ev.name)

if strcmp(params.save_as, ev.name)
  params.save_as = '';
end

% before modifying the pat object, make sure files, etc. are OK
if ~isempty(params.save_as)
  % set new save files, regardless of whether we're saving right now
  % set the default results directory
  ev_name = params.save_as;
  if isempty(params.res_dir)
    params.res_dir = fullfile(fileparts(get_ev_dir(ev)), ev_name);
  end
  
  % use "events" subdirectory of res_dir
  ev_dir = fullfile(params.res_dir, 'events');
  ev_file = fullfile(ev_dir, ...
                     objfilename('events', ev_name, ev.source));
else
  ev_name = ev.name;
  ev_file = ev.file;
end

% check to see if there's already a pattern there that we don't want
% to overwrite
if params.save_mat && ~params.overwrite && exist(ev_file, 'file')
  fprintf('"%s" events exist. Skipping...\n', ev_name)
  return
end

events = get_mat(ev);
if ~isempty(params.event_filter)
  % run on a subset of events
  sub_events = filterStruct(events, params.event_filter);
  sub_len = length(sub_events);
  sub_events = f(sub_events, f_inputs{:});

  % merge back into the complete events structure
  events = union_structs(sub_events, events, {'mstime'});
  
  % in case merging messes up order
  events = sort_events(events);
else
  events = f(events, f_inputs{:});
end

ev.modified = true;
ev.len = length(events);

if ~isempty(params.save_as)
  % change the name and point to the new file
  ev.name = ev_name;
  ev.file = ev_file;
  if ~exist(ev_dir, 'dir')
    mkdir(ev_dir)
  end
end

if params.save_mat
  % save the pattern
  ev = set_mat(ev, events, 'hd');
  if ~isempty(params.save_as)
    fprintf('saved as "%s".\n', ev.name)
  else
    fprintf('saved.\n')
  end
else
  % just save to workspace
  ev = set_mat(ev, events, 'ws');  
  if ~isempty(params.save_as)
    fprintf('returning as "%s".\n', ev.name)
  else
    fprintf('updated.\n')
  end
end

