function [ind,fast,slow] = findBlinks(dat,thresh,params)
%FINDBLINKS - Index the blinks in an EEG signal.
%
% Uses a fast and slow running average to detect fast and large
% changes in amplitude (blinks and eye movements).
%
% FUNCTION:
%  [ind,fast,slow] = findBlinks(dat,thresh,params)
%
% INPUT ARGS:
%   dat = dat;     % vector of EEG data.
%   thresh = 100;  % fast threshold in mV used for marking blinks
%   params = [.5 .5 .975 .025];  % a,b,c,d values of running average
%
% OUTPUT ARGS:
%   ind- Length of dat, logical vector with 1s where shows blink
%   fast,slow- Fast and slow running averages for diagnostic purposes
%

if ~exist('thresh','var')
  thresh = 100;
end
if ~exist('params','var')
  params = [.5, .5, .975, .025];
end

% init the two running averages
fast = zeros(1,length(dat));
slow = zeros(1,length(dat));
%ind = logical(zeros(1,length(dat)));

% params
a = params(1);
b = params(2);
c = params(3);
d = params(4);

fast_start = 0;
slow_start = mean(dat(1:10));

for i = 1:length(dat)
  % update the running averages
  if i > 1
    fast(i) = a*fast(i-1) + b*(dat(i)-slow(i-1));
    slow(i) = c*slow(i-1) + d*dat(i);
  else
    fast(i) = a*fast_start + b*(dat(i)-slow_start);
    slow(i) = c*slow_start + d*dat(i);    
  end
  
  % check for thresh
  %ind(i) = abs(fast(i))>=thresh;
  
end

% check for thresh
ind = logical(abs(fast)>=thresh);
  
