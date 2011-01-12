function subj = import_channels(subj, locs_file)
%IMPORT_CHANNELS   Import channel information for one subject.
%
%  subj = import_channels(subj, locs_file)
%
%  INPUTS:
%       subj:  subject object.
%
%  locs_file:  path to an EEGLAB-compatible electrode locations file.
%              See readlocs for supported formats. Alternatively,
%              can be an integer indicating the number of channels.
%
%  OUTPUTS:
%       subj:  subject object with an added "chan" structure holding
%              channel information.
%
%  NOTES:
%   Currently only imports the channel labels from the locs_file. Once
%   functions are adapted to allow saving of chan structures to disk,
%   will also import location information.

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

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must input a subject structure.')
elseif ~isscalar(subj)
  error('Only one subject at a time.')
end

% number of channels
if isnumeric(locs_file)
  n_chans = locs_file;
  for i = 1:n_chans
    subj.chan(i).number = uint32(i);
    subj.chan(i).label = sprintf('%d', i);
  end
  return
end

% input for readlocs
elocs = readlocs(locs_file);
numbers = num2cell(uint32(1:129));
%[elocs.number] = number{:};
%[elocs.label] = elocs.labels;

% for now, just include the number (index) and label from the
% locs file. Need to implement saving channel structures to disk
% so we can have the location information without taking up too
% much memory.
labels = {elocs.labels};
labels = cellfun(@(x) strrep(x, 'E', ''), labels, 'UniformOutput', false);
subj.chan = struct('number', numbers, 'label', labels);

