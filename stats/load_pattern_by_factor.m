function [x, levels] = load_pattern_by_factor(pat, bin_defs, varargin)
%LOAD_PATTERN_BY_FACTOR   Load pattern data organized by factors in events.
%
%  Use to load pattern data organized by different factors defined by
%  events. Each dimension of the returned pattern corresponds to one
%  factor, and the elements of the dimension to levels of the factor.
%
%  [x, levels] = load_pattern_by_factor(pat, bin_defs)
%
%  INPUTS:
%       pat:  pattern object. All dimensions execpt events must be
%             singleton.
%
%  bin_defs:  cell array with one element for each factor. bin_defs{i}
%             will be input to make_event_index to define the
%             levels of factor i.
%
%  OUTPUTS:
%        x:  matrix of pattern data. x(i,j,k,...) contains data
%            corresponding to level i of factor 1, level j of factor 2,
%            level k of factor 3, ect.
%
%   levels:  cell array with one element for each factor, containing the
%            original labels for the factors. levels{i}{j} contains the
%            label for level j of factor i.

def.data_type = 'pattern';
def.field = '';
opt = propval(varargin, def);

pat_size = patsize(pat.dim);
if any(pat_size(2:end) > 1)
  error('Dimensions other than events must be singleton.')
end

% load the factors
n_factors = length(bin_defs);
n_samples = pat_size(1);
index = NaN(n_samples, n_factors);
events = get_dim(pat.dim, 'ev');
levels = cell(1, n_factors);
uindex = cell(1, n_factors);
x_size = NaN(1, n_factors);
for i = 1:n_factors
  [index(:,i), levels{i}] = make_event_index(events, bin_defs{i});
  uindex{i} = nanunique(index(:,i));
  x_size(i) = length(uindex{i});
end

% fill the matrix, organized by factor levels
x = NaN(x_size);

switch opt.data_type
  case 'pattern'
    pattern = get_mat(pat);
  case 'events'
    pattern = [events.(opt.field)];
  otherwise
    error('Unknown data_type: %s', opt.data_type);
end

for i = 1:n_samples
  % get the index for each dimension for this sample
  ind = cell(1, n_factors);
  for j = 1:n_factors
    ind{j} = index(i,j);
  end
  
  x(ind{:}) = pattern(i);
end

