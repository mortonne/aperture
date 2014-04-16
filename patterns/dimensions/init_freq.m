function freq = init_freq(freqs, labels, vals)
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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

if nargin < 3
  vals = [];
end

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
elseif ~isempty(labels) && (length(labels) ~= length(freqs))
  error('labels must be the same length as freqs.')
end

% make the time struct, with one element for each time bin
freqs_cell = num2cell(freqs);
if isempty(labels)
  % if no user-specified labels, print default labels
  labels = cellfun(@(x)sprintf('%.2f Hz', x), freqs_cell, 'UniformOutput', ...
                   false);
end
freq = struct('vals', freqs_cell, 'avg', freqs_cell, 'label', labels);

if ~isempty(vals)
  for i = 1:size(vals, 1)
    freq(i).vals = vals(i,:);
  end
end
