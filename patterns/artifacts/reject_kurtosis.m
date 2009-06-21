function [mask, kurt] = reject_kurtosis(pattern, thresh, params)
%REJECT_KURTOSIS   Reject samples of a pattern based on kurtosis.
%
%  [mask, kurt] = reject_kurtosis(pattern, thresh)

% input checks
if ~exist('pattern','var') || ~isnumeric(pattern)
  error('You must pass a pattern matrix.')
end
if ~exist('thresh','var')
  thresh = 5;
end
if ~exist('params','var')
  params = struct;
end

params = structDefaults(params, ...
                        'verbose', true);

% get kurtosis along the time dimension
kurt = kurtosis(pattern, 1, 3);

% [events X channels X 1 X freqs] mask
mask = kurt > thresh;

if params.verbose
  if ndims(pattern)==4
    fprintf(['Threw out %d event-channel-freqs ' ...
            'out of %d with kurtosis greater than %d.\n'], ...
            nnz(mask), numel(mask), thresh)
  else
    fprintf(['Threw out %d event-channels ' ...
            'out of %d with kurtosis greater than %d.\n'], ...
            nnz(mask), numel(mask), thresh)
  end
end

% make the mask fill the time dimension
mask = repmat(mask, [1 1 size(pattern,3) 1]);
