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

