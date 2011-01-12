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
