function [pat2, pattern2, events2] = patBins(pat1, params, pattern1, events1, mask1)
%function [pat2, pattern2, events2] = patBins(pat1, params, pattern1, events1, mask1)

params = structDefaults(params,  'masks', {},  'field', '',  'eventBinLabels', '',  'chanbins', [],  'chanbinlabels', {},  'MSbins', [],  'MSbinlabels', {},  'freqbins', [],  'freqbinlabels', {});

if ~exist('pattern1', 'var')
  % load the pattern from disk
  [pattern1, events1] = loadPat(pat1, params,1);
else
  % must apply masks manually
  for m=1:length(params.masks)
    thisMask = filterStruct(mask1,'strcmp(name, varargin{1})', params.masks{m});
    pattern1(thisMask.mat) = NaN;
  end
end

% initialize
pat2 = pat1;
pattern2 = pattern1;
events2 = events1;

% start the averaging
fprintf('Binning pattern "%s"...', pat1.name)

% bin events if necessary
if ~isempty(params.field)
  fprintf('events...');
  
  % bin events using a field from the events struct
  if exist('events1', 'var')
    [pat2.dim.ev, events2, bine] = eventBins(pat1.dim.ev, params, events1);
  else
    [pat2.dim.ev, events2, bine] = eventBins(pat1.dim.ev, params);
  end
  
  oldSize = pad_vec(size(pattern2),4);
  temp = NaN(length(bine), oldSize(2), oldSize(3), oldSize(4));
  for e=1:length(bine)
    temp(e,:,:,:) = nanmean(pattern2(bine{e},:,:,:),1);
  end
  pattern2 = temp;
end

% bin channels
if ~isempty(params.chanbins)
  fprintf('channels...');
  
  % bin channels by number or region
  [pat2.dim.chan, binc] = chanBins(pat1.dim.chan, params);
  
  oldSize = pad_vec(size(pattern2),4);
  temp = NaN(oldSize(1), length(binc), oldSize(3), oldSize(4));
  for c=1:length(binc)
    temp(:,c,:,:) = nanmean(pattern2(:,binc{c},:,:),2);
  end
  pattern2 = temp;
end

% bin time
if ~isempty(params.MSbins)
  fprintf('time...');
  
  % bin time using MS windows
  [pat2.dim.time, bint] = timeBins(pat1.dim.time, params);
  
  oldSize = pad_vec(size(pattern2),4);
  temp = NaN(oldSize(1), oldSize(2), length(bint), oldSize(4));
  for t=1:length(bint)
    temp(:,:,t,:) = nanmean(pattern2(:,:,bint{t},:),3);
  end
  pattern2 = temp;
end

% bin frequency
if ~isempty(params.freqbins)
  fprintf('frequency...');
  
  % bin frequency using freq windows
  [pat2.dim.freq, binf] = freqBins(pat1.dim.freq, params);
  
  oldSize = pad_vec(size(pattern2),4);
  temp = NaN(oldSize(1), oldSize(2), oldSize(3), length(binf));
  for f=1:length(binf)
    temp(:,:,:,f) = nanmean(pattern2(:,:,:,binf{f}),4);
  end
  pattern2 = temp;
end
fprintf('\n')

function vec2 = pad_vec(vec1, len)

vec2 = ones(1,len);
vec2(1:length(vec1)) = vec1;
