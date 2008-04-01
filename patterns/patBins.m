function [pat2, pattern2, events2] = patBins(pat1, pattern1, events1, mask1)

params = pat1.params;

params = structDefaults(params,  'masks', {},  'field', '',  'eventBinLabels', '',  'chanBins', [],  'chanBinLabels', {},  'MSbins', [],  'MSbinLabels', {},  'freqBins', [],  'freqBinLabels', {});

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
%[freq, binf] = freqBins(pat1.dim.freq, params);
freq = init_freq();
binf{1} = 1;

pat2 = init_pat(pat1.name, pat1.file, params, ev, chan, time, freq);

if ~exist('pattern1', 'var')
  % load the pattern from disk
  [pattern1, events1] = loadPat(pat1, params, 1);
else
  % must apply masks manually
  for m=1:length(params.masks)
    thisMask = filterStruct(mask, 'strcmp(name, varargin{1})', params.masks{m});
    pattern1(thisMask.mat) = NaN;
  end
end

% do the averaging
fprintf('Binning pattern "%s"...\n', pat1.name);
pattern2 = NaN(ev.len, length(chan), length(time), length(freq));
for e=1:length(bine)
  meane = mean(pattern1(bine{e},:,:,:), 1);
  for c=1:length(binc)
    meanc = mean(meane(:,binc{c},:,:), 2);
    for t=1:length(bint)
      meant = mean(meanc(:,:,bint{t},:), 3);
      for f=1:length(binf)
	pattern2(e,c,t,f) = mean(meant(:,:,:,binf{f}), 4);
      end
    end
  end
end
