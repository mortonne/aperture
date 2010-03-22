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
