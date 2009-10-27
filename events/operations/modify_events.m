function ev = modify_events(ev, params, ev_name, res_dir)
%MODIFY_EVENTS   Modify an existing events structure.
%
%  ev = modify_events(ev, params, ev_name, res_dir)
%
%  INPUTS:
%       ev:  an events object.
%
%   params:  a structure specifying options for modifying the
%            events structure. See below.
%
%  ev_name:  string identifier for the new events structure.  If
%            empty or not specified, the name will not be changed.
%
%  res_dir:  directory where the new events structure will be saved.
%            Default: get_ev_dir(ev)
%
%  OUTPUTS:
%       ev:  a modified events object.
%
%  PARAMS:
%  overwrite       - boolean indicating whether existing events
%                    structures should be overwritten. (false)
%  eventFilter     - string to be passed into filterStruct to filter
%                    the events structure. ('')
%  replace_eegfile - cell array of strings. Each row specifies one
%                    string replacement to run on events.eegfile, e.g.
%                     strrep(eegfile, replace_eegfile{r,1}, ...
%                             replace_eegfile{r,2})
%                    is run for each row. Useful for fixing references
%                    to EEG data. ({})
%  ev_mod_fcn      - handle to a function of the form:
%                     [events, ...] = fcn(events, ...)
%                    Set this option to use a custom function to modify
%                    the events structure.
%  ev_mod_inputs   - cell array of additional inputs to ev_mod_fcn. ({})
%
%  EXAMPLES:
%   % filter an events structure and overwrite the old events
%   params = [];
%   params.eventFilter = 'strcmp(type, ''WORD'')';
%   params.overwrite = true;
%   ev = modify_events(ev, params);
%
%   % run an arbitrary function to modify events for all subjects
%   old_ev = 'events'; % name of the ev object to modify
%   new_ev = 'my_events'; % name to save the new events under
%   params.ev_mod_fcn = @my_function;
%   subj = apply_to_ev(subj, old_ev, @modify_events, {params, new_ev});

% input checks
if ~exist('ev','var')
  error('You must pass an events object.')
end
if ~isfield(ev, 'modified')
  ev.modified = false;
end
if ~exist('params','var')
  params = struct;
end
if ~exist('ev_name','var') || isempty(ev_name)
  ev_name = ev.name;
end
if ~exist('res_dir','var')
  res_dir = get_ev_dir(ev);
end

% default parameters
params = structDefaults(params, ...
                        'overwrite', false, ...
                        'eventFilter','', ...
                        'replace_eegfile',{}, ...
                        'ev_mod_fcn',[], ...
                        'ev_mod_inputs',{});

fprintf('modifying events structure "%s"...\n', ev.name)

% if the ev_name is different, save events to a new file
if ~strcmp(ev.name, ev_name)
  saveas = true;
  ev.name = ev_name;
  ev_file = fullfile(res_dir, sprintf('%s_%s.mat', ev.name, ev.source));
else
  saveas = false;
  ev_file = ev.file;
end

% if the file exists and we're not overwriting, return
ev_loc = get_obj_loc(ev);
if strcmp(ev_loc, 'hd') && ~params.overwrite && exist(ev_file, 'file')
  fprintf('events %s exist. Skipping...\n', ev.name)
  return
end

% load the events structure
events = get_mat(ev);

% update the events file
ev.file = ev_file;

% run strrep on the eegfile of each event
if ~isempty(params.replace_eegfile)
  rep = params.replace_eegfile';
  events = rep_eegfile(events, rep{:});
end

% filter the events structure
events = filterStruct(events, params.eventFilter);

% run a custom script to modify events
if ~isempty(params.ev_mod_fcn)
  events = params.ev_mod_fcn(events, params.ev_mod_inputs{:});
end

% save
ev = set_mat(ev, events);
if strcmp(ev_loc, 'hd')
  if saveas
    fprintf('saved as "%s".\n', ev_name)
  else
    fprintf('saved.\n')
  end
else
  ev.modified = true;
end
