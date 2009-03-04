function h = correct_mult_comp(p,alpha,method)
%CORRECT_MULT_COMP   Correct p-values for multiple comparisons.
%
%  h = correct_mult_comp(p,alpha,method)
%
%  INPUTS:
%        p:  array of p-values.
%
%    alpha:  scalar indicating the desired false alarm rate. Default is 0.05.
%
%   method:  string indicating which method to use for correcting multiple
%            comparisons. Choices are 'bonferoni', 'holms', and 'fdr'.
%
%  OUTPUTS:
%        h:  logical array indicating whether each value in p is significant.

% input checks
if ~exist('p','var')
  error('You must pass an array of p-values')
end
if ~exist('alpha','var')
  alpha = 0.05;
end
if ~exist('method','var')
  method = '';
end

switch lower(method)
  case 'bonferoni'
  fprintf('performing Bonferoni correction for multiple comparisons\n');
  h = p<=(alpha ./ numel(p));
  
  case 'holms'
  % test the most significatt significance probability against alpha/N, the second largest against alpha/(N-1), etc.
  fprintf('performing Holms correction for multiple comparisons\n');
  [p_sort,indx] = sort(p(:));                     % this sorts the significance probabilities from smallest to largest
  mask = p_sort<=(alpha ./ ((length(p):-1:1)'));    % compare each significance probability against its individual threshold
  h = false(size(p));
  h(indx) = mask;
  
  case 'fdr'
  fprintf('performing FDR correction for multiple comparisons\n');
  h = fdr(p, alpha);
  if isempty(h)
    h = false(size(p));
  end
  
  otherwise
  fprintf('not performing a correction for multiple comparisons\n');
  h = p<=alpha;
end
