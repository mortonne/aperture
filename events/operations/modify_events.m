function [ev,events] = modify_events(ev,params,ev_name,res_dir)
%MODIFY_EVENTS   Modify an existing events structure.
%
%  [ev, events] = modify_events(ev, params, ev_name, res_dir)
%
%  INPUTS:
%       ev:  an events object.
%
%   params:  a structure specifying options for modifying the
%            events structure. See below.
%
%  ev_name:  string identifier for the new events structure. If
%            empty, the old events will be replaced.
%            default: ''
%
%  res_dir:  the new events will be saved in:
%             [res_dir]/events/[ev_name].mat
%            default: fileparts(fileparts(ev.file))
%
%  OUTPUTS:
%       ev:  a modified events object.
%
%   events:  the modified events structure.
%
%  PARAMS:
%  eventFilter     - string to be passed into filterStruct to filter
%                    the events structure. default: '' (no filtering)
%  replace_eegfile - cell array of strings. Each row specifies one
%                    string replacement to run on events.eegfile, e.g.
%                     strrep(eegfile, replace_eegfile{r,1}, ...
%                             replace_eegfile{r,2})
%                    is run for each row. Useful for fixing references
%                    to EEG data.
%  ev_mod_fcn      - handle to a function of the form:
%                     [events, ...] = ev_mod_fcn(events, ...)
%  ev_mod_inputs   - cell array of additional inputs to ev_mod_fcn.
%
%  NOTES:
%   The 'eventFilter' and 'replace_eegfile' options are included for
%   convenience; the same functionality can be achieved using the 'evmodfcn'
%   and 'evmodinput' fields.
%
%  EXAMPLES:
%   % filter an events structure and overwrite the old events
%   ev = getobj(exp.subj(1), 'ev', 'my_events');
%   params.eventFilter = 'strcmp(type, ''WORD'')';
%   [ev, events] = modify_events(ev, params);
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
if ~exist('params','var')
  params = [];
end
if ~exist('ev_name','var')
  ev_name = '';
end
if ~exist('res_dir','var')
  res_dir = fileparts(fileparts(ev.file));
end

% default parameters
params = structDefaults(params, ...
                        'overwrite', false, ...
                        'eventFilter','', ...
                        'replace_eegfile',{}, ...
                        'ev_mod_fcn',[], ...
                        'ev_mod_inputs',{});
oldev = ev;
ev_source = oldev.source;

% set the filepath for the new events
if ~isempty(ev_name)
  % save to a new file
  ev_file = fullfile(res_dir,'events',sprintf('%s_%s.mat', ev_name, ev_source));
else
  % overwrite the old events
  ev_name = oldev.name;
  ev_file = oldev.file;
end

try
  % check input files and prepare output files
  prepFiles(oldev.file, ev_file, params);
catch err
  % something is wrong with i/o
  if strfind(err.identifier, 'fileExists')
    return
    elseif strfind(err.identifier, 'fileNotFound')
    rethrow(err)
    elseif strfind(err.identifier, 'fileLocked')
    rethrow(err)
  end
end

% load the events structure
events = load_events(oldev);

fprintf('modifying events structure "%s"...', oldev.name)

% run strrep on the eegfile of each event
if ~isempty(params.replace_eegfile)
  for e=1:length(events)
    for r=params.replace_eegfile'
	    events(e).eegfile = strrep(events(e).eegfile,r{1},r{2});
    end
  end
end

% filter the events structure
events = filterStruct(events, params.eventFilter);

% run a custom script to modify events
if ~isempty(params.ev_mod_fcn)
  events = params.ev_mod_fcn(events,params.ev_mod_inputs{:});
end

% save
save(ev_file, 'events');
if strcmp(oldev.name, ev_name)
  fprintf('saved.\n')
  else
  fprintf('saved as "%s".\n', ev_name)
end

% create a new ev object
ev = init_ev(ev_name, ev_source, ev_file, length(events));
