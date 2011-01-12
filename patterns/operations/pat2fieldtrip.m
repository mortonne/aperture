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

% channel labels
chan = pat.dim.chan;
data.label = cell(1,length(chan));
for i=1:length(chan)
  data.label{1,i} = sprintf('E%d', chan(i).number);
end

% sample rate
data.fsample = get_pat_samplerate(pat);

% load the pattern
pattern = load_pattern(pat);

% fieldtrip can't handle NaNs...for now, just hack them out
%if any(isnan(pattern(:)))
%  pat_mean = nanmean(pattern(:));
%  num_nans = sum(isnan(pattern(:)));

%  fprintf('%d NaNs found...replacing with overall mean (%.4f).\n', num_nans, pat_mean)
%  pattern(isnan(pattern)) = pat_mean;
%end

% initialize fieldtrip vars
n_trials = size(pattern,1);
data.trial = cell(1,n_trials);
data.time = cell(1,n_trials);

for i=1:n_trials
  % write data for this event
  data.trial{1,i} = squeeze(pattern(i,:,:));
  
  % write time axis for this event (in seconds)
  data.time{1,i} = get_dim_vals(pat.dim, 'time')./1000;
end
