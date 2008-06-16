function freq = init_freq(freqs, labels)

if ~exist('freqs', 'var') || isempty(freqs)
  freq = struct('vals', [],  'avg', [],  'label', '');
  return
end

if ~exist('labels', 'var')
  labels = {};
end

for f=1:length(freqs)
  freq(f).vals = freqs(f);
  freq(f).avg = freqs(f);
  if ~isempty(labels)
    freq(f).label = labels{f};
  else
    freq(f).label = sprintf('%d Hz', freqs(f));
  end
end
