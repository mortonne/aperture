function data = pat2fieldtrip(pat)
%PAT2FIELDTRIP   Convert a pat object to fieldtrip format.
%
%  data = pat2fieldtrip(pat)
%
%  INPUTS:
%      pat:  pat object.
%
%  OUTPUTS:
%     data:  fieldtrip-compatible data structure.

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

if ~exist('pat','var')
  error('You must pass a pattern object.')
end

data = struct;

% channel labels
%data.label = get_dim_labels(pat.dim, 'chan');
n_chans = patsize(pat.dim, 'chan');
data.label = cell(1, n_chans);
for i = 1:n_chans
  data.label{i} = sprintf('E%d', i);
end

% sample rate
try
  data.fsample = get_pat_samplerate(pat);
catch err
  % check that we don't have only one sample
  time = get_dim_vals(pat.dim, 'time');
  if length(time) == 1 & time==0
    warning('Only one time point, setting arbitrary fsample of 1.')
    data.fsample = 1;
  elseif length(time) == 1
    warning('Only one time point, setting arbitrary fsample.')
    data.fsample = 1/time;
  else
    % different kind of error, rethrow
    rethrow(err)
  end
end

% load the pattern matrix
pattern = get_mat(pat);
[n_trials, n_chans, n_times, n_freqs] = size(pattern);

if n_freqs > 1
  data.time = get_dim_vals(pat.dim, 'time');
  data.freq = get_dim_vals(pat.dim, 'freq');
  data.dimord = 'chan_freq_time';

  %data.powspctrm = zeros(n_trials, n_chans, n_freqs, n_times, 'single');
  %data.powspctrm = single(permute(pattern, [1 2 4 3]));
  data.powspctrm = single(permute(pattern, [2 4 3 1]));
else
  % times for each trial
  data.time = cell(1, n_trials);
  for i = 1:n_trials
    data.time{1,i} = get_dim_vals(pat.dim, 'time') ./ 1000;
  end

  data.trial = cell(1, n_trials);
  for i = 1:n_trials
    data.trial{1,i} = squeeze(pattern(i,:,:));
  end

  % check dimensions, mainly needed for using only one timebin
  if size(data.trial{1,i}, 2) ~= length(data.time{1,i})
    data.trial{1,i} = data.trial{1,i}';
  end

  data.dimord = 'chan_time';
end
