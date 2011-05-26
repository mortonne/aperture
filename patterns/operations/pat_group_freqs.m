function [n, labels] = pat_group_freqs(subj, pat_name, dim, bins, ...
                                       labels, filter)
%PAT_GROUP_FREQS   Frequency of different group types in patterns.
%
%  Use this to see how frequent different groups (defined by any pattern
%  dimension) are for a set of subjects.
%
%  [n, labels] = pat_group_freqs(subj, pat_name, dim, bins, labels,
%                                filter)
%
%  INPUTS:
%      subj:  vector of subjects.
%
%  pat_name:  name of the pattern to examine.
%
%       dim:  dimension to group. See read_dim_input for allowed
%             formats.
%
%      bins:  bin definitions. See bin_pattern for formats allowed for
%             each dimension.
%
%    labels:  cell array of strings giving labels for each bin.
%
%    filter:  filter string to apply to the dimension before binning.
%             See filter_pattern.
%
%  OUTPUTS:
%         n:  [subjects X bins] matrix giving the number of elements in
%             each bin.
%
%    labels:  corresponding bin labels

if ~exist('filter', 'var')
  filter = '';
end
if ~exist('labels', 'var')
  labels = {};
end

% get Ns and labels for each subject
n_subj = length(subj);
all_n = cell(1, n_subj);
all_labels = cell(1, n_subj);
for i = 1:n_subj
  fprintf('%s\n', subj(i).id)
  pat = getobj(subj(i), 'pat', pat_name);
  [subj_n, subj_labels] = get_subj_freq(pat, dim, bins, labels, filter);
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


function [n, labels] = get_subj_freq(pat, dim, bins, labels, filter)

  [dim_name, dim_number] = read_dim_input(dim);
  if strcmp(dim_name, 'ev')
    dim_long_name = 'event';
  else
    dim_long_name = dim_name;
  end

  if ~isempty(filter)
    % filter events but not the pattern matrix
    pat = patFilt(pat, [dim_long_name 'Filter'], filter);
  end

  % get bins from the event bins definitions
  [temp, bins] = patBins(pat, [dim_long_name 'bins'], bins, ...
                         [dim_long_name 'binlabels'], labels);
  
  % number of elements in each bin
  n = NaN(1, length(bins{dim_number}));
  for i = 1:length(n)
    n(i) = length(bins{dim_number}{i});
  end
  
  % corresponding labels
  labels = get_dim_labels(temp.dim, dim_name);

