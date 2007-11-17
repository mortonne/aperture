function pat = loadPat(patFile, masks, eventsFile, eventfilter)
%pat = loadPat(patFile, masks, eventsFile, eventfilter)
%
%LOADPAT - loads one subject's pattern, and applies any specified
%masks and event filters
%

load(patFile)

if exist('masks', 'var') && ~isempty(masks)
  
  mask = filterStruct(mask, 'ismember(name, varargin{1})', masks);
  for m=1:length(mask)
    pat.mat(mask(m).mat) = NaN;
  end
end

if exist('eventFilter', 'var') && ~isempty(eventFilter)
  load(eventsFile);
  pat.mat = pat.mat(inStruct(events, eventFilter),:,:,:);
end
