function [n, labels] = pat_event_freqs(subj, pat_name, event_bins, ...
                                       event_filter)
%PAT_EVENT_FREQS   Frequency of different event types in patterns.
%
%  Use this to see how frequent different types of events are for
%  a set of subjects.
%
%  [n, labels] = pat_event_freqs(subj, pat_name, event_bins, event_filter)

if ~exist('event_filter', 'var')
  event_filter = '';
end

% get Ns and labels for each subject
n_subj = length(subj);
all_n = cell(1, n_subj);
all_labels = cell(1, n_subj);
parfor i = 1:n_subj
  fprintf('%s\n', subj(i).id)
  pat = getobj(subj(i), 'pat', pat_name);
  [subj_n, subj_labels] = get_subj_freq(pat, event_bins, event_filter);
  all_n{i} = subj_n;
  all_labels{i} = subj_labels;
end

% get them in the same order, set missing values
labels = unique([all_labels{:}]);
n_labels = length(labels);
n = zeros(n_subj, n_labels);
for i = 1:n_subj
  [tf, loc] = ismember(all_labels{i}, labels);
  n(i,loc) = all_n{i};
end

function [n, labels] = get_subj_freq(pat, event_bins, event_filter)

  if ~isempty(event_filter)
    % filter events but not the pattern matrix
    pat = patFilt(pat, 'eventFilter', event_filter);
  end

  % get bins from the event bins definitions
  [temp, bins] = patBins(pat, 'eventbins', event_bins);
  
  % number of events in each bin
  n = NaN(1, length(bins{1}));
  for i = 1:length(n)
    n(i) = length(bins{1}{i});
  end
  
  % corresponding labels
  labels = get_dim_labels(temp.dim, 'ev');

