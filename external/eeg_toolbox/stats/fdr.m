function [pID,pN] = fdr(p,q)
%FDR - Determine the false discovery rate for multiple comparisons
%
% FUNCTION:
%   [pID,pN] = fdr(p,q)
% 
% INPUT ARGS:
%   p   - vector of p-values
%   q   - False Discovery Rate level
%
% OUTPUT ARGS:
%   pID - p-value threshold based on independence or positive dependence
%   pN  - Nonparametric p-value threshold
%

%______________________________________________________________________________
% @(#)FDR.m	1.3 Tom Nichols 02/01/18


p = sort(p(:));
V = length(p);
I = (1:V)';

cVID = 1;
cVN = sum(1./(1:V));

% p-thresh for independence or positive dependence
pID = p(max(find(p<=I/V*q/cVID)));

% p-thresh for non-parametric tests
pN = p(max(find(p<=I/V*q/cVN)));

