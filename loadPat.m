function varargout = loadPat(patFile, masks, eventsFile, eventFilter, replace_eegfile)
%varargout = loadPat(patFile, masks, eventsFile, eventFilter, replace_eegfile)
%
%LOADPAT - loads one subject's pattern, and applies any specified
%masks and event filters
%

if ~exist('replace_eegfile', 'var')
  replace_eegfile = {};
end

load(patFile)

if exist('masks', 'var') && ~isempty(masks)
  
  mask = filterStruct(mask, 'ismember(name, varargin{1})', masks);
  for m=1:length(mask)
    pattern(mask(m).mat) = NaN;
  end
end

if exist('eventFilter', 'var')
  events = loadEvents(eventsFile, replace_eegfile);
  inds = inStruct(events, eventFilter);
  
  varargout(1) = {pattern(inds,:,:,:)};
  varargout(2) = {events(inds)};
else
  varargout(1) = {pattern};
end
