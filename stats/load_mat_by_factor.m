function [x, levels] = load_mat_by_factor(mat, events, bin_defs)
%LOAD_MAT_BY_FACTOR   Rearrange a pattern matrix by conditions.
%
%  Takes an [events X n X m X p] matrix, and converts it to an
%  [factor1 X factor 2 X ... factor N X n X m X p] matrix. Can be
%  used to prepare pattern matrices for easier statistical analysis.
%
%  INPUTS:
%       mat:  [events X n X m X p] numeric array.
%
%    events:  events structure with information used to define the
%             factors to be used.
%
%  bin_defs:  bin definitions to determine the factors. See
%             make_event_index for allowed formats.
%
%  OUTPUTS:
%        x:  [factor1 X factor 2 X ... factor N X n X m X p]
%            numeric array.
%
%   levels:

s_full = ones(1, 4);
s = size(mat);
s_full(1:length(s)) = s;
s = s_full;

% load the factors
n_factors = length(bin_defs);
n_samples = s(1);
index = NaN(n_samples, n_factors);

levels = cell(1, n_factors);
uindex = cell(1, n_factors);
x_size = NaN(1, n_factors);
for i = 1:n_factors
  [index(:,i), levels{i}] = make_event_index(events, bin_defs{i});
  uindex{i} = nanunique(index(:,i));
  x_size(i) = length(uindex{i});
end

% fill the matrix, organized by factor levels
x = NaN([x_size s(2:end)]);

for i = 1:n_samples
  % get the index for each dimension for this sample
  ind = cell(1, n_factors);
  for j = 1:n_factors
    ind{j} = index(i,j);
  end
  
  for j = 1:s(2)
    for k = 1:s(3)
      for l = 1:s(4)
        x(ind{:}, j, k, l) = mat(i, j, k, l);
      end
    end
  end
end
