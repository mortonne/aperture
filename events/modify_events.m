function [ev,status] = modify_events(ev,params,evname,resDir)
%MODIFY_EVENTS
%

if isstruct(params)
  params = structDefaults(params, 'eventFilter','', 'overwrite',0);
end

if ~exist('resDir','var')
  [resDir,filename] = fileparts(ev.file);
end
if ~exist('evname','var') || isempty(evname)
  evname = [ev.name '_mod'];
end

status = 0;
oldev = ev;

% initialize the new ev object
if ~strcmp(oldev.name,evname)
  ev.name = evname;
  ev.file = fullfile(resDir, sprintf('%s_%s.mat', evname, ev.source));
end

% check the input and output
if prepFiles(oldev.file, ev.file, params)~=0
  status = 1;
  return
end

load(oldev.file);

events = filterStruct(events, params.eventFilter);

%{
for i=1:2:length(varargin)
  % get the function to evaluate
  evmodfcn = varargin{i};
  
  % get other inputs, if there are any
  if i<length(varargin)
    inputs = varargin{i+1};
    if ~iscell(inputs)
      inputs = {inputs};
    end
    else
    inputs = {};
  end
  
  fprintf('Running %s...', func2str(evmodfcn))
  
  % eval the function, using the object and the cell array of inputs
  events = evmodfcn(events, inputs{:});
  
  if isempty(events)
    % this subject failed; may be locked
    error('Function %s returned empty events.', func2str(evmodfcn))
  end
end
%}

% update the number of events
ev.len = length(events);
% save
save(ev.file, 'events');
