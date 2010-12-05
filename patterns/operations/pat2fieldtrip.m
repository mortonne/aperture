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
