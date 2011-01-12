function bad = bad_channels(events, channels, heog_channels, veog_channels)
%BAD_CHANNELS   Find channels with poor contact.
%
%  Search for channels with poor contact within EEG referenced by an
%  events structure. A channel's "badness" is assumed to be the same
%  within each unique EEG file in events. A channel is marked as bad
%  if the mean or standard deviation of that channel is more than 10
%  standard deviations away from the distribution of those statistics
%  across all channels.
%
%  bad = bad_channels(events, channels, heog_channels, veog_channels)

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

eegfiles = unique({events.eegfile});
bad = false(length(events), length(channels));
for i=1:length(eegfiles)
  fileroot = eegfiles{i};

  heog = load_chan(fileroot, heog_channels);
  
  veog = mean([load_chan(fileroot, veog_channels{1}); 
               load_chan(fileroot, veog_channels{2})]);
  
  x = [heog' veog'];
  clear heog veog
  
  m = NaN(1, length(channels));
  s = NaN(1, length(channels));
  parfor j=1:length(channels)
    eeg = load_chan(fileroot, channels(j));
    [b, dev, stats] = glmfit(x, eeg);
    m(j) = mean(stats.resid);
    s(j) = std(stats.resid);
  end
  
  mask = abs(zscore(m)) > 5 | abs(zscore(s)) > 5;
  fileroot_ind = strcmp({events.eegfile}, fileroot);
  
  % repeat this mask for all events corresponding to this file
  bad(fileroot_ind, :) = repmat(mask, nnz(fileroot_ind), 1);

  %if any(mask)
  %  keyboard
  %end
  
  % heog = load_chan(fileroot, heog_channels);
  
  % veog = mean([load_chan(fileroot, veog_channels{1}); 
  %              load_chan(fileroot, veog_channels{2})]);
  
  % x = [heog' veog'];
  % clear heog veog
  
  % k = NaN(1, length(channels));
  % m = NaN(1, length(channels));
  % s = NaN(1, length(channels));
  % am = NaN(1, length(channels));
  % bl = NaN(1, length(channels));
  % parfor j=1:length(channels)
  %   eeg = load_chan(fileroot, channels(j));
  %   %good = eeg < 100;
  %   good = true(size(eeg));
  %   eeg = eeg(good);
    
  %   [b, dev, stats] = glmfit(x(good,:), eeg);
  %   %stats.resid = eeg;
  %   k(j) = kurtosis(stats.resid);
  %   m(j) = mean(stats.resid);
  %   s(j) = std(stats.resid);
  %   am(j) = max(abs(stats.resid));
  %   bl(j) = mean(findBlinks(stats.resid, 10));
  % end

  % mask = zscore(m) > 10 | zscore(s) > 10;
  
  
  % clf
  % %subplot(5,1,1); bar(k)
  % subplot(4,1,1); bar(m)
  % subplot(4,1,2); bar(s)
  % subplot(4,1,3); bar(am)
  % subplot(4,1,4); bar(bl)
end

