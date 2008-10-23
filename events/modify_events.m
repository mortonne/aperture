function [ev,err] = modify_events(ev,params,evname,resDir)
%MODIFY_EVENTS   Make changes to events that are stored in an ev object.
%   EV = MODIFY_EVENTS(EV,PARAMS,EVNAME,RESDIR) modifies the events 
%   stored in EV. Options for modifying events are specified in the 
%   PARAMS structure.
%
%   EVNAME specifies the name of the output EV object, which contains the
%   filename and length of the modified events. The default is [EV.name]_mod. 
%
%   If EVNAME is different than EV.name, modified events will be saved in a 
%   new file; otherwise, existing events will be overwritten. Modified events 
%   are saved in RESDIR/events. If RESDIR is not specified, it defaults to 
%   the parent directory of EV.file.
%
%    Optional params fields:
%     'eventFilter'     String to be passed into filterStruct to filter the
%                       events struct. The filter will be applied before 
%                       params.evmodfcn is run. Default: ''
%     'replace_eegfile' Cell array of strings, where each row gives a pair
%                       of strings to be passed into strrep, with
%                       events(i).eegfile as the first argument. Useful for
%                       associating events with different EEG data
%     'evmodfcn'        Handle to a function that modifies an events structure.
%                       The first input argument and first output argument 
%                       should be events. This will be run after the 
%                       eventFilter has been applied
%     'evmodinput'      Cell array of optional additional inputs to 
%                       params.evmodfcn
%
%   NOTE: The 'eventFilter' and 'replace_eegfile' options are included for
%   convenience; the same functionality can be achieved using the 'evmodfcn'
%   and 'evmodinput' fields.
%
%   Example:
%    params.eventFilter = 'strcmp(type,''WORD'')';
%    params.replace_eegfile = {'olddir', 'newdir'};
%    ev = modify_events(ev,params,'word_events_neweegfile');

if ~exist('params','var')
  params = [];
end
params = structDefaults(params, 'eventFilter','', 'replace_eegfile',{}, 'evmodfcn',[], 'evmodinput',{}, 'overwrite',0);
if ~exist('resDir','var')
  resDir = fileparts(ev.file);
end
if ~exist('evname','var') || isempty(evname)
  evname = [ev.name '_mod'];
end

oldev = ev;

% initialize the new ev object
if ~strcmp(oldev.name,evname)
  ev.name = evname;
  ev.file = fullfile(resDir, sprintf('%s_%s.mat', evname, ev.source));
end

% check the input and output
err = prepFiles(oldev.file, ev.file, params);
if err
  return
end

load(oldev.file);

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
if ~isempty(params.evmodfcn)
  events = params.evmodfcn(events,params.evmodinput{:});
end

% update the number of events
ev.len = length(events);

% save
save(ev.file, 'events');
fprintf('%s created.', evname)
