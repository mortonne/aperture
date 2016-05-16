function [hbar, herr] = ebar(varargin)
%EBAR Bar graph with error bars.
%   EBAR(X,Y,L,U) draws the columns of the M-by-N matrix Y as M groups
%   of N vertical bars.  The vector X must not have duplicate
%   values. L and U contain the lower and upper bounds for each point
%   in Y.
%
%   If X is empty, the default value is used of X=1:M.
%
%   EBAR(X,Y,E) plots Y with error bars [Y-E Y+E].
%
%   EBAR(AX,...) plots into AX instead of GCA.
%
%   [HBAR, HERR] = EBAR(...) returns a vector of handles to barseries
%   objects in HBAR and a vector of handles to errorbarseries objects
%   in HERR.

if ishandle(varargin{1})
  ax = varargin{1};
  varargin = varargin(2:end);
end

if length(varargin) == 4
  x = varargin{1};
  y = varargin{2};
  l = varargin{3};
  u = varargin{4};
  rl = y - l;
  ru = u - y;
elseif length(varargin) == 3
  x = varargin{1};
  y = varargin{2};
  err = varargin{3};
  rl = err;
  ru = err;
end

if isvector(y) && size(y, 2) > 1
  y = y';
  rl = rl';
  ru = ru';
  x = x';
end

[n_group, n_bar] = size(y);

% make a temporary plot to set y-limits to a sane value
if isempty(x)
  x = [1:n_group]';
end
xe = repmat(x, [1 n_bar]);
htemp = errorbar(xe, y, rl, ru);
y_lim = get(gca, 'YLim');
delete(htemp)

% plot bars
hold on

hbar = bar(x, y);

for i = 1:n_bar
  if verLessThan('matlab', '8.4')
    % HG1
    patch_x = get(get(hbar(i), 'Children'), 'XData');
    bx = mean(patch_x([1 3],:));
  else
    % HG2
    bx = hbar(i).XData + hbar(i).XOffset;
  end
  herr(i) = errorbar(bx, y(:,i), rl(:,i), ru(:,i), 'k', ...
                     'LineStyle', 'none');
end
set(gca, 'YLim', y_lim);
hold off
