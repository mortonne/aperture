function freq = init_freq(freqs, labels)
%INIT_FREQ   Initialize a frequency dimension.
%
%  freq = init_freq(freqs, labels)
%
%  INPUTS:
%    freqs:  vector of frequency values in Hz.
%
%   labels:  (optional) cell array of strings giving labels for each
%            frequency bin.
%
%  OUTPUTS:
%     freq:  struct with information about a frequency dimension.

% input checks
if ~exist('freqs', 'var') || isempty(freqs)
  freq = struct('vals', [],  'avg', [],  'label', '');
  return
elseif ~isnumeric(freqs)
  error('freqs must be numeric.')
end
if ~exist('labels', 'var')
  labels = {};
elseif ~iscellstr(labels)
  error('labels must be a cell array of strings.')
elseif length(labels) ~= length(freqs)
  error('labels must be the same length as freqs.')
end

% make the time struct, with one element for each time bin
freqs_cell = num2cell(freqs);
if isempty(labels)
  % if no user-specified labels, print default labels
  labels = cellfun(@(x)sprintf('%d Hz', x), freqs_cell, 'UniformOutput', ...
                   false);
end
freq = struct('vals', freqs_cell, 'avg', freqs_cell, 'label', labels);
