function h = correct_mult_comp(p,alpha,method,verbose)
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
if ~exist('verbose','var')
  verbose = false;
end

switch lower(method)
  case 'bonferoni'
  if verbose
    fprintf('performing Bonferoni correction for multiple comparisons\n');
  end
  h = p<=(alpha ./ numel(p));
  
  case 'holms'
  % test the most significatt significance probability against alpha/N, the second largest against alpha/(N-1), etc.
  if verbose
    fprintf('performing Holms correction for multiple comparisons\n');
  end
  [p_sort,indx] = sort(p(:));                     % this sorts the significance probabilities from smallest to largest
  mask = p_sort<=(alpha ./ ((length(p):-1:1)'));    % compare each significance probability against its individual threshold
  h = false(size(p));
  h(indx) = mask;
  
  case 'fdr'
  if verbose
    fprintf('performing FDR correction for multiple comparisons');
  end
  q = fdr(p, alpha);
  if isempty(q)
    if verbose
      fprintf('...no significant values')
    end
    h = false(size(p));
    else
    h = p<=q;
  end
  if verbose
    fprintf('\n')
  end
  
  otherwise
  if verbose
    fprintf('not performing a correction for multiple comparisons\n');
  end
  h = p<=alpha;
end
