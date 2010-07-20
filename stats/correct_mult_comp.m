function alpha_pc = correct_mult_comp(p, alpha_fw, method)
%CORRECT_MULT_COMP   Correct p-values for multiple comparisons.
%
%  alpha_pc = correct_mult_comp(p, alpha_fw, method)
%
%  INPUTS:
%         p:  array of p-values.
%
%  alpha_fw:  desired familywise Type I error rate. Default is 0.05.
%
%    method:  string indicating which method to use for correcting
%             for multiple comparisons. Choices are 'bonferroni',
%             'holms', and 'fdr'.
%
%  OUTPUTS:
%  alpha_pc:  per-comparison alpha to use to give the desired familywise
%             Type I error rate.

% input checks
if ~exist('p', 'var')
  error('You must pass an array of p-values')
end
if ~exist('alpha_fw', 'var')
  alpha_fw = 0.05;
end
if ~exist('method', 'var')
  method = '';
end

% find the threshold we need to set family-wise false alarm rate
% to alpha
switch lower(method)
 case {'bonferoni', 'bonferroni'}
  alpha_pc = alpha_fw / numel(p);

 case 'fdr'
  alpha_pc = fdr(p, alpha_fw);
  if isempty(alpha_pc)
    alpha_pc = 0;
  elseif alpha_pc < 0
    keyboard
  end
  
 otherwise
  alpha_pc = alpha_fw;
end
