function [mask, kurt] = reject_kurtosis(pattern, thresh, varargin)
%REJECT_KURTOSIS   Reject samples of a pattern based on kurtosis.
%
%  [mask, kurt] = reject_kurtosis(pattern, thresh, ...)
%
%  INPUTS:
%   pattern:  [events X channels X time X freq] matrix.
%
%    thresh:  maximum allowable kurtosis for an event to be included.
%             Default: 5
%
%  OUPUTS:
%      mask:  logical array the same size as pattern; true samples mark
%             events with high kurtosis.
%
%  kurtosis:  corresponding kurtosis values.
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
  thresh = 5;
end

% options
defaults.verbose = true;
params = propval(varargin, defaults);

% get kurtosis along the time dimension
kurt = kurtosis(pattern, 1, 3);

% [events X channels X 1 X freqs] mask
mask = kurt > thresh;

if params.verbose
  if ndims(pattern)==4
    fprintf(['Removed %d event-channel-freqs ' ...
            'of %d (%.f%%) with kurtosis > %d. (m=%.4f s=%.4f)\n'], ...
            nnz(mask), numel(mask), (nnz(mask) / numel(mask)) * 100, ...
            thresh, mean(kurt(:)), std(kurt(:)))
  else
    fprintf(['Removed %d event-channels ' ...
            'of %d (%.f%%) with kurtosis > %d. (m=%.4f s=%.4f)\n'], ...
            nnz(mask), numel(mask), (nnz(mask) / numel(mask)) * 100, ...
            thresh, mean(kurt(:)), std(kurt(:)))
  end
end

% make the mask fill the time dimension
mask = repmat(mask, [1 1 size(pattern,3) 1]);
