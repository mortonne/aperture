function [x, group] = stat_mat2regs(mat)
%STAT_MAT2REGS   Convert data arranged on multiple dimensions to vector format.
%
%  [x, group] = stat_mat2regs(mat)
%
%  INPUTS:
%     mat:  matrix of observed data. Each dimension corresponds to
%           one factor, and the length of dimensions to the number of
%           levels for that factor.
%
%  OUTPUTS:
%        x:  [numel(mat) x 1] vector of observed data.
%
%    group:  [numel(mat) x ndims(mat)] vector of labels indicating data
%            grouping.

s = size(mat);
n = ndims(mat);
m = numel(mat);

group = NaN(m, n);
for i = 1:n
  ssing = s;
  ssing(i) = 1;
  sinv = ones(1, n);
  sinv(i) = s(i);
  ind = reshape(1:s(i), sinv);
  imat = repmat(ind, ssing);
  group(:,i) = imat(:);
end

x = mat(:);
