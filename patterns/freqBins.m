function [freq2, binf] = freqBins(freq1, params)
%[freq2, binf] = freqBins(freq1, params)

if ~exist('freq1', 'var')
  freq1 = [];
end
if ~exist('params', 'var')
  params = struct();
end

params = structDefaults(params, 'freqBins', {},  'freqBinLabels', {});

% make the new freq bins
if ~isempty(params.freqBins)
  
  % get the current list of frequencies
  avgfreq = [freq1.avg];
  
  for f=1:length(params.freqbins)
    % define this bin
    binf{f} = find(avgfreq>=params.freqBins(f,1) & avgfreq<params.freqBins(f,2));
    
    freq2(f).vals = avgfreq(binf{f});
    freq2(f).avg = mean(freq2(f).vals);
    
    % update the labels
    if ~isempty(params.freqBinLabels)
      freq2(f).label = params.freqBinLabels{f};
    else
      freq2(f).label = sprintf('%d to %d Hz', freq2(f).vals(1), freq2(f).vals(end));
    end
  end
  
elseif ~isempty(freq1)
  
  % copy the existing struct
  freq2 = freq1;
  
  % define the bins
  for f=1:length(freq2)
    binf{f} = f;
  end
  
else
  freq2 = init_freq();
  binf = {};
end
