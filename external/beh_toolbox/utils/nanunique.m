function [b, i, j] = nanunique(a, varargin)
%NANUNIQUE Set unique, ignoring NaNs.
%   B = NANUNIQUE(A) for the array A returns the same values as in
%   A but with no repetitions. B will also be sorted.
%
%   [B,I,J] = NANUNIQUE(...) also returns index vectors I and J such
%   that, if nA contains the non-NaN values of A, B = A(I) and nA = B(J).
%   
%   [B,I,J] = NANUNIQUE(...,'first') returns the vector I to index the
%   first occurrence of each unique value in A.  UNIQUE(...,'last'),
%   the default, returns the vector I to index the last occurrence.

[b, i, j] = unique(a, varargin{:});

if isnumeric(b)
  i_nan = find(isnan(a(:)));
  j_nan = find(isnan(b));
  b = b(~isnan(b));

  i = i(~ismember(i, i_nan));
  j = j(~ismember(j, j_nan));
end

