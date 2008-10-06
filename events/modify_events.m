function [ev,err] = modify_events(ev,params,evname,resDir)
%MODIFY_EVENTS   Make changes to an ev object and the corresponding events.
%   EV = MODIFY_EVENTS(EV,PARAMS,EVNAME,RESDIR) modifies EV according to
%   options in the PARAMS struct. If EVNAME is different than EV.name,
%   modified events will be saved in a new file. RESDIR specifies where
%   the new events will be saved.
%
%    Params:
%     'eventFilter'     String to be passed into filterEvents to filter the
%                       events struct
%     'replace_eegfile' Cell array of strings, where each row gives a pair
%                       of strings to be passed into strrep, with
%                       events(i).eegfile as the first argument
%     'evmodfcn'        Handle to a function that modifies events. The first
%                       input argument and first output argument should be
%                       events. This will be run after the eventFilter has
%                       been applied
%     'evmodinput'      Cell array of optional additional inputs to 
%                       params.evmodfcn
%
%   Example:
%    params.eventFilter = 'strcmp(type,''WORD'')';
%    params.replace_eegfile = {'olddir', 'newdir'};
%    ev = modify_events(ev,params,'word_events_neweegfile');
%

if isstruct(params)
  params = structDefaults(params, 'eventFilter','', 'replace_eegfile',{}, 'evmodfcn',[], 'evmodinput',{}, 'overwrite',0);
end

if ~exist('resDir','var')
  [resDir,filename] = fileparts(ev.file);
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
