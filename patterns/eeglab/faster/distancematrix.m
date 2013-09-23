function [distpol, distxyz, distproj] = distancematrix(EEG, eeg_chans)
%DISTANCEMATRIX   Pairwise distance between electrodes.
%
%  [distpol, distxyz, distproj] = distancematrix(EEG, eeg_chans)
  
% Copyright (C) 2010 Hugh Nolan, Robert Whelan and Richard Reilly, Trinity College Dublin,
% Ireland
% nolanhu@tcd.ie, robert.whelan@tcd.ie
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

num_chans = size(EEG.data, 1);

% polar distance
distpol = zeros(length(eeg_chans), length(eeg_chans));
for i = eeg_chans
  for j = eeg_chans
    r1 = EEG.chanlocs(i).radius;
    r2 = EEG.chanlocs(j).radius;
    t1 = EEG.chanlocs(i).theta;
    t2 = EEG.chanlocs(j).theta;
    
    distpol(i,j) = sqrt(r1^2 + r2^2 - (2 * r1 * r2 * cosd(t1 - t2)));
  end
end

% prepare coordinates
% NWM: why default to 0? Seems brittle
locs = EEG.chanlocs;
for i = eeg_chans
  if ~isempty(locs(i).X)
    Xs(i) = locs(i).X;
  else
    Xs(i) = 0;
  end
  if ~isempty(locs(i).Y)
    Ys(i) = locs(i).Y;
  else
    Ys(i) = 0;
  end
  if ~isempty(locs(i).Z)
    Zs(i) = locs(i).Z;
  else
    Zs(i) = 0;
  end
end

% NWM: don't know why they are rounding
Xs = round2(Xs, 6);
Ys = round2(Ys, 6);
Zs = round2(Zs, 6);

% euclidian distance
% NWM: this might be incorrect. Should change to use pdist
for i = eeg_chans
  for j = eeg_chans
    distxyz(i,j) = dist(Xs(i), Xs(j)) + dist(Ys(i), Ys(j)) + ...
        dist(Zs(i), Zs(j));
  end
end

% NWM: not sure what this represents
D = max(max(distxyz));
distproj = (pi-2*(acos(distxyz./D))).*(D./2);

function d = dist(in1,in2)
  d = sqrt(abs(in1.^2 - in2.^2));

function num = round2(num,decimal)
  num = num .* 10^decimal;
  num = round(num);
  num = num ./ 10^decimal;

