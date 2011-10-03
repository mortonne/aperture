function bad = bad_channels(eeg_files, channels, heog_channels, ...
                            veog_channels, thresh_m, thresh_sd)
%BAD_CHANNELS   Find channels with poor contact.
%
%  Search for channels with poor contact. A channel's "badness" is
%  assumed to be the same within each unique EEG file in events. A
%  channel is marked as bad if the mean or standard deviation of that
%  channel is more than 5 standard deviations away from the distribution
%  of those statistics across all channels, after EOG has been regressed
%  out.
%
%  bad = bad_channels(eeg_files, channels, heog_channels, veog_channels)
%
%  INPUTS:
%      eeg_files:  cell array of EEG file roots.
%
%       channels:  vector of numbers indicating which channels to
%                  examine.
%
%  heog_channels:  numbers of a pair of horizontal EOG electrodes.
%
%  veog_channels:  cell array of numbers of vertical EOG electrode
%                  pairs.
%
%       thresh_m:  threshold (in z-scores) of a channel's mean, for that
%                  channel to be considered "bad"
%
%      thresh_sd:  threshold (in z-scores) of a channel's standard
%                  deviation, for that channel to be considered "bad"
%
%  OUTPUTS:
%      bad:  [EEG files X channels] logical array; true for EEG
%            files/channels that probably had poor contact.

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

bad = false(length(eeg_files), length(channels));
for i = 1:length(eeg_files)
  fileroot = eeg_files{i};
  fprintf('Searching for bad channels in %s...\n', fileroot)

  % load voltage from EOG pairs
  heog = load_chan(fileroot, heog_channels);
  veog1 = load_chan(fileroot, veog_channels{1});
  veog2 = load_chan(fileroot, veog_channels{2});
  
  x = [heog' veog1' veog2'];
  clear heog veog1 veog2
  
  % for each channel, regress out EOG, then get stats over time
  m = NaN(1, length(channels));
  s = NaN(1, length(channels));
  for j = 1:length(channels)
    fprintf('%d ', channels(j))
    eeg = load_chan(fileroot, channels(j));
    [b, dev, stats] = glmfit(x, eeg);
    m(j) = mean(stats.resid);
    s(j) = std(stats.resid);
  end
  fprintf('\n')

  % find channels with unusually large means or variance
  bad(i,:) = abs(zscore(m)) > thresh_m | zscore(s) > thresh_sd;
  
  % print them
  if any(bad(i,:))
    bad_channels = find(bad(i,:));
    fprintf('Found %d bad channels:', length(bad_channels))
    
    for i = 1:length(bad_channels)
      fprintf(' %d', bad_channels(i))
    end
    fprintf('\n')
  end

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

