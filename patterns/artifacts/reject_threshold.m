function [mask, absmax] = reject_threshold(pattern, thresh, varargin)
%REJECT_THRESHOLD   Reject samples of a pattern based on max absolute value.
%
%  [mask, absmax] = reject_threshold(pattern, thresh, ...)
%
%  INPUTS:
%   pattern:  [events X channels X time] matrix.
%
%    thresh:  maximum allowable range (over time) for an event-channel
%             to be included.  Default: 100
%
%  OUPUTS:
%      mask:  logical array the same size as pattern; true samples mark
%             events with high max absolute values.
%
%    absmax:  maximum absolute value of each event-channel.
%
%  PARAMS:
%   verbose - if true, more information will be printed. (true)

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
if ~exist('pattern', 'var') || ~isnumeric(pattern)
  error('You must pass a pattern matrix.')
end
if ~exist('thresh', 'var')
  thresh = 100;
end

% options
defaults.verbose = true;
params = propval(varargin, defaults);

% get event-channels with any samples above the threshold
%absmax = max(max(abs(pattern), [], 3), [], 4);
absmax = range(pattern, 3);
bad_event_chans = absmax > thresh;

% check for channels that are bad for all events
bad_chans = all(bad_event_chans, 1);
if any(bad_chans)
  warning('%d channels completely excluded.', nnz(bad_chans))
end

if params.verbose
  fprintf(['Removed %d event-channels of %d (%.f%%) with abs. val. ' ...
          '> %d.\n'], nnz(bad_event_chans), numel(bad_event_chans), ...
          (nnz(bad_event_chans) / numel(bad_event_chans)) * 100, thresh)
end

% expand the mask to fit the pattern
pat_size = size(pattern);
mask = repmat(bad_event_chans, [1 1 pat_size(3:end)]);

