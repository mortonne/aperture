function subj = import_channels(subj, n_chans)
%IMPORT_CHANNELS   Import channel information for one subject.
%
%  subj = import_channels(subj, n_chans)
%
%  For now, this doesn't actually import anything; it just makes a basic
%  chan structure with numbers and blank labels.  In the future, this
%  will be able to read various types of channel locations files an add
%  them in an eeg_ana-friendly manner.

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must input a subject structure.')
elseif ~isscalar(subj)
  error('Only one subject at a time.')
end
  
subj.chan = struct('number', num2cell(1:n_chans), 'label', '');

