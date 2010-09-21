function tf = isunique(x)
%ISUNIQUE   True if an array contains unique elements.
%
%  tf = isunique(x)

tf = length(unique(x(:))) == numel(x);

