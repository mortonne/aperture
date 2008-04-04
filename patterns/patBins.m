function [pat2, pattern2, events2] = patBins(pat1, params, pattern1, events1, mask1)

params = structDefaults(params,  'masks', {},  'field', '',  'eventBinLabels', '',  'chanBins', [],  'chanBinLabels', {},  'MSbins', [],  'MSbinLabels', {},  'freqBins', [],  'freqBinLabels', {});

if ~exist('pattern1', 'var')
  % load the pattern from disk
  [pattern1, events1] = loadPat(pat1, params);
else
  % must apply masks manually
  for m=1:length(params.masks)
    thisMask = filterStruct(mask1,'strcmp(name, varargin{1})', params.masks{m});
    pattern1(thisMask.mat) = NaN;
  end
end

% bin events using a field from the events struct
if exist('events1', 'var')
  [ev, bine, events2] = eventBins(pat1.dim.ev, params, events1);
else
  [ev, bine, events2] = eventBins(pat1.dim.ev, params);
end

% bin channels by number or region
[chan, binc] = chanBins(pat1.dim.chan, params);

% bin time using MS windows
[time, bint] = timeBins(pat1.dim.time, params);

% bin frequency using freq windows
[freq, binf] = freqBins(pat1.dim.freq, params);

pat2 = init_pat(pat1.name, pat1.file, params, ev, chan, time, freq);

% do the averaging
fprintf('Binning pattern "%s"...', pat1.name); 

% get vectors of the sizes of the start and end patterns
pat1size = size(pattern1);
ps1 = ones(1,4);
ps1(1:length(pat1size)) = pat1size;
ps2 = [ev.len, length(chan), length(time), length(freq)];

% bin events if necessary
if ps2(1)<ps1(1)
  fprintf('events...');
  temp = NaN(ps2(1), ps1(2), ps1(3), ps1(4));
  for e=1:length(bine)
    temp(e,:,:,:) = nanmean(pattern1(bine{e},:,:,:),1)
  end
  pattern2 = temp;
end

% bin channels
if ps2(2)<ps1(2)
  fprintf('channels...');
  temp = NaN(ps1(1), ps2(2), ps1(3), ps1(4));
  for c=1:length(binc)
    temp(:,c,:,:) = nanmean(pattern1(:,binc{c},:,:),2);
  end
  pattern2 = temp;
end

% bin time
if ps2(3)<ps1(3)
  fprintf('time...');
  temp = NaN(ps1(1), ps1(2), ps2(3), ps1(4));
  for t=1:length(bint)
    temp(:,:,t,:) = nanmean(pattern1(:,:,bint{t},:),3);
  end
  pattern2 = temp;
end

% bin frequency
if ps2(4)<ps1(4)
  fprintf('frequency...');
  temp = NaN(ps1(1), ps1(2), ps1(3), ps2(4));
  for f=1:length(binf)
    temp(:,:,f,:) = nanmean(pattern1(:,:,binf{f},:),3);
  end
  pattern2 = temp;
end

fprintf('\n');
