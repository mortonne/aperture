function events = rep_eegfile(events, varargin)
%REP_EEGFILE   Run strrep on the eegfile field of an events structure.
%
%  events = rep_eegfile(events, X1, X2, Y1, Y2, ...)
%
%  INPUTS:
%    events:  an events structure. Must have an "eegfile" field.
%
%  varargin:  any number of string pairs, where the first is the string
%             to replace, and the second is the string to replace it
%             with.
%
%  OUTPUTS:
%    events:  events structure with a modified eegfile field.
%
%  EXAMPLE:
%   % change the EEG file field to point to rereferenced data
%   events = rep_eegfile(events, 'eeg.noreref', 'eeg.reref');

% input checks
if ~exist('events','var') || ~isstruct(events)
  error('You must pass an events structure.')
elseif ~isfield(events, 'eegfile')
  error('events must have an "eegfile" field.')
elseif mod(length(varargin),2)~=0
  error('length of varargin must be a multiple of two.')
end

% get the EEG file field
eegfile = {events.eegfile};
empty = cellfun(@isempty, eegfile);
if all(empty)
  return
end

% run strrep on each input pair
for i = 1:2:length(varargin)
  to_replace = varargin{i};
  replacement = varargin{i+1};
  eegfile(~empty) = strrep(eegfile(~empty), to_replace, replacement);
end

% add the modified field back in
[events.eegfile] = eegfile{:};
