function [alpha_fw] = correct_mult_comp(p,alpha,method)
%CORRECT_MULT_COMP   Correct p-values for multiple comparisons.
%
%  alpha_fw = correct_mult_comp(p,alpha,method)
%
%  INPUTS:
%         p:  array of p-values.
%
%     alpha:  scalar indicating the desired false alarm rate. Default is 0.05.
%
%    method:  string indicating which method to use for correcting multiple
%             comparisons. Choices are 'bonferroni', 'holms', and 'fdr'.
%
%  OUTPUTS:
%  alpha_fw:  adjusted alpha that gives a family-wise false alarm rate.

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

% find the threshold we need to set family-wise false alarm rate
% to alpha
switch lower(method)
  case {'bonferoni', 'bonferroni'}
  alpha_fw = alpha/numel(p);

  case 'fdr'
  alpha_fw = fdr(p, alpha);
  if isempty(alpha_fw)
    alpha_fw = 0;
  elseif alpha_fw<0
    keyboard
  end
  
  otherwise
  alpha_fw = alpha;
end
