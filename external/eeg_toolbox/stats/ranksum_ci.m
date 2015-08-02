function [p, h, stats, Ws] = ranksum_ci(x,y,alpha,tail)
%RANKSUM_CI - Wilcoxon rank sum test that two populations are identical.
%
%   Modified the matlab version to return 95% confidence
%   interval. (PBS)
%
%   Modified to make it faster in the case of many ties between x
%   and y (JJ, 12/07).
%
%   Modified to completely ignore NaNs. (JDM, 3/13)
%
%
%   P = RANKSUM(X,Y,ALPHA,TAIL) returns the significance for testing the
%   null hypothesis that the populations generating two independent
%   samples, X and Y, are identical. X and Y are vectors but can have
%   different lengths.  The alternative is that the median of the X
%   population is shifted from the median of the Y population by a
%   non-zero amount.
%
%   ALPHA is the desired level of significance and must be a scalar
%   between zero and one.  Its default value is 0.05.
%
%   P is the probability of observing a result equally or more 
%   extreme than the one using the data (X and Y) if the null  
%   hypothesis is true. If P is near zero, this casts doubt on
%   this hypothesis.
%
%   The null hypothesis is: "means are equal".
%   For TAIL =  0  the alternative hypothesis is: "means are not equal."
%   For TAIL =  1, alternative: "mean of X is greater than mean of Y."
%   For TAIL = -1, alternative: "mean of X is less than mean of Y."
%   TAIL = 0 by default.
%
%   [P, H] = RANKSUM(X,Y,ALPHA) also returns H, the result of the
%   hypothesis test.  H is 0 if the medians of X and Y are not
%   significantly different, and 1 if they are significantly
%   different.
%
%   [P, H, STATS] = RANKSUM(X,Y,ALPHA) also returns a STATS structure
%   with one or two fields.  The field 'ranksum' contains the value of
%   the rank sum statistic.  If the sample size is large, then P is
%   calculated using a normal approximation and the field 'zval'
%   contains the value of the normal (Z) statistic.


%   B.A. Jones 12-28-96
%   Copyright 1993-2002 The MathWorks, Inc. 
% $Revision: 1.5 $
if nargin < 4
  tail = 0;
  if nargin < 3
    alpha = 0.05;
  end
end


if (length(alpha)>1)
   error('RANKSUM requires a scalar ALPHA value.');
end
if ((alpha <= 0) | (alpha >= 1))
   error('RANKSUM requires 0 < ALPHA < 1.');
end

[nx, colx] = size(x);
[ny, coly] = size(y);

if min(nx, colx) ~= 1 | min(ny,coly) ~= 1,
   error('RANKSUM requires vector rather than matrix data.');
else
  % remove NaNs
  x(isnan(x)) = [];
  [nx, colx] = size(x);
  y(isnan(y)) = [];
  [ny, coly] = size(y);
end 

if ~isa(x,'double')||~isa(y,'double')
  error('RANKSUM requires doubles');
end

if nx == 1
   nx = colx;
   x = x';
end
if ny == 1,
   ny = coly;
   y = y';
end

if nx <= ny
   smsample = x;
   lgsample = y;
   ns = nx;
   nl = ny;
else
   smsample = y;
   lgsample = x;
   ns = ny;
   nl = nx;
end

% Compute the rank sum statistic based on the smaller sample
%[ranks, tieadj] = tiedrank([smsample; lgsample]);
[ranks, tieadj] = tr([smsample; lgsample]);
xrank = ranks(1:ns);

w = sum(xrank);

wmean = ns*(nx + ny + 1)/2;

if ns < 10 & (nx+ny) < 20     % Use the sampling distribution of W.
   allpos = nchoosek(ranks,ns);
   sumranks = sum(allpos,2);
   np = length(sumranks);
   if w < wmean
      p = 2*length(find(sumranks <= w))./np;
   else 
      p = 2*length(find(sumranks >= w))./np;
   end
   p = min(p, 1);        % p>1 means w is in the middle and double-counted
else    % Use the normal distribution approximation of W.
   tiescor = 2 * tieadj / ((nx+ny) * (nx+ny-1));
   wvar  = nx*ny*((nx + ny + 1) - tiescor)/12;
   wc = w - wmean;
   z = (wc - 0.5 * sign(wc))/sqrt(wvar);
   p = normcdf(z,0,1);

   if tail==0
     p = 2*min(p,1-p);
   elseif (tail==1 & nx <=ny) | (tail==-1 & nx>ny)
     p = 1-p;
   else
     p = p;
   end
   
   if (nargout > 2)
      stats.zval = z;
   end
   
   % pbs- reverse calc to return wc and .05 sig cutoff
   pd = .05/2;
   pd = max(pd,1-pd);
   zd = norminv(pd,0,1);
   wcd = zd * sqrt(wvar);   
end



if nargout > 1,
   h = (p<=alpha);
   if (nargout > 2)
      stats.ranksum = w;
      if (nargout > 3)
	if ~(ns < 10 & (nx+ny) < 20)
	  if nx > ny
	    % flip the sign of wc
	    wc = -wc;
	  end
	  Ws = [wc wcd]; 
	else
	  % it was a small sample, not included in code, yet
	  Ws = [0 0];
	end
      end              
   end
end



function [r,tieadj] = tr(x)
%josh modified this from the matlab tiedrank function for speed, and to not deal with the
%optional tieadj and bidirectional flags from the original matlab version

%TR Local tiedrank function to compute results for one column

% Sort, then leave the NaNs (which are sorted to the end) alone
[sx, rowidx] = sort(x(:));
numNaNs = sum(isnan(x));
xLen = numel(x) - numNaNs;

% Use ranks counting from low end
ranks = [1:xLen NaN(1,numNaNs)]';

tieadj = 0;

%run-length encoding code modified from
%http://home.online.no/~pjacklam/matlab/doc/mtt/index.html
runEndIndex = [ find(sx(1:end-1) ~= sx(2:end))' length(sx) ]; 
runLen = diff([ 0 runEndIndex ]); 
runStartIndex=runEndIndex-runLen+1;

for i=find(runLen>1)
  ranks(runStartIndex(i):runEndIndex(i))=(runStartIndex(i)+runEndIndex(i))/2;
  tieadj=tieadj+runLen(i)*(runLen(i)-1)*(runLen(i)+1)/2;
end

r(rowidx) = ranks;
r = reshape(r,size(x));

