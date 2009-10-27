function mask = reject_threshold(pattern, thresh, varargin)
%REJECT_THRESHOLD   Reject samples of a pattern based on max absolute value.
%
%  mask = reject_threshold(pattern, thresh, args)
%
%  INPUTS:
%   pattern:  [events X channels X time X freq] matrix.
%
%    thresh:  maximum allowable absolute value for an event to be
%             included.  Default: 100
%
%  OUPUTS:
%      mask:  logical array the same size as pattern; true samples mark
%             events with high max absolute values.
%
%  ARGS:
%  verbose - if true, more information will be printed. (true)

% input checks
if ~exist('pattern', 'var') || ~isnumeric(pattern)
  error('You must pass a pattern matrix.')
end
if ~exist('thresh','var')
  thresh = 100;
end

defaults.verbose = true;
params = propval(varargin, defaults);

% get event-channels with any samples above the threshold
bad_samples = abs(pattern) > thresh;
bad_event_chans = any(any(bad_samples, 4), 3);

% check for channels that are bad for all events
bad_chans = all(bad_event_chans, 1);
if any(bad_chans)
  warning('%d channels completely excluded.', nnz(bad_chans))
end

if params.verbose
  fprintf(['Threw out %d event-channels out of %d with abs. val. ' ...
          'greater than %d.\n'], nnz(bad_event_chans), ...
          numel(bad_event_chans), thresh)
end

% expand the mask to fit the pattern
pat_size = size(pattern);
mask = repmat(bad_event_chans, [1 1 pat_size(3:end)]);

