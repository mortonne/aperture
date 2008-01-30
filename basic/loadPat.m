function [pattern, events] = loadPat(patFile, masks, eventsFile, eventFilter)
%[pattern, events] = loadPat(patFile, masks, eventsFile, eventFilter)
%
%LOADPAT - loads one subject's pattern, and applies any specified
%masks and event filters
%

if ~exist('replace_eegfile', 'var')
  replace_eegfile = {};
end

if iscell(patFile)
  for i=1:length(patFile)
    
  end
else
  load(patFile)
end

if exist('masks', 'var') && ~isempty(masks)
  
  mask = filterStruct(mask, 'ismember(name, varargin{1})', masks);
  for m=1:length(mask)
    pattern(mask(m).mat) = NaN;
  end
end

if exist('eventsFile', 'var')
  events = loadEvents(eventsFile);
else
  events = [];
end

if exist('eventFilter', 'var') && ~isempty(eventFilter)
  
  inds = inStruct(events, eventFilter);  
  pattern = pattern(inds,:,:,:);
  events = events(inds);
end
