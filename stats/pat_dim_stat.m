function pat = pat_dim_stat(pat, reg_defs, f_stat, f_inputs, ...
                            stat_name, var_names)
%PAT_DIM_STAT   Run a statistical test including non-events dimensions as factors.
%
%  For example, could use this function to test whether an ERP component
%  is greater in one hemisphere than another, and whether this interacts
%  with an experimental condition.
%
%  INPUTS:
%        pat:  pattern object.
%
%   reg_defs:  cell array of regressor definitions. See make_event_index
%              for possible inputs.
%
%     f_stat:  function handle to a statistics function of the form:
%               [a,b,c,...] = f_stat(x, group, ...)
%              where x is a vector of data from the pattern, and group
%              is a cell array of numeric labels indicating the
%              different factors. group{i}(j) gives the level of factor
%              i for observation j. The factors are ordered with first
%              the events labels (determined from reg_defs), followed by
%              channel bins, time bins, and frequency bins.
%
%   f_inputs:  cell array of additional inputs to f_stat.
%
%  stat_name:  string name for the created statistics object.
%
%  var_names:  names of variables returned by f_stat. Default:
%              {'p', 'statistic', 'res'}
%
%  OUTPUTS:
%        pat:  pattern object with a new stat object containing the
%              results of the test.

if ~exist('var_names', 'var')
  var_names = {'p', 'statistic', 'res'};
end

% make the event regressors
labels = {};
levels = {};
reg_dim = [];
if ~isempty(reg_defs)
  % load events for this pattern
  events = get_dim(pat.dim, 'ev');
  for i = 1:length(reg_defs)
    [reg_labels, reg_levels] = make_event_index(events, reg_defs{i});
    labels = [labels {reg_labels}];
    levels = [levels {reg_levels}];
    reg_dim = [reg_dim 1];
  end
  clear events
else
  labels = {};
  levels = {};
end

% add other regressors for non-singleton dimensions
pattern = get_mat(pat);
s = size(pattern);
dim_ind = setdiff(find(s > 1), 1);
for i = 1:length(dim_ind)
  dim_labels = [1:s(dim_ind(i))]';
  dim_levels = get_dim_labels(pat.dim, dim_ind(i));
  
  labels = [labels {dim_labels}];
  levels = [levels {dim_levels}];
  reg_dim = [reg_dim dim_ind(i)];
end

% iterate over elements of the pattern
n_levels = cellfun(@length, labels);
n_fact = length(labels);
n_cell = s(1) * prod(n_levels(reg_dim ~= 1));
ind = cell(1, n_fact);
x = NaN(n_cell, 1);
group = repmat({NaN(n_cell, 1)}, 1, n_fact);
for i = 1:n_cell
  % unpack the dimension indices
  [ind{:}] = ind2sub(s, i);
  
  % save this element of the pattern into the vector
  x(i) = pattern(ind{:});
  
  % get the corresponding factor labels for this element
  for j = 1:n_fact
    % what dimension is this factor indexing?
    fact_ind = ind{reg_dim(j)};
    
    % get the correct label
    group{j}(i) = labels{j}(fact_ind);
  end
end

n_out = length(var_names);
out = cell(1, n_out);
[out{:}] = f_stat(x, group, f_inputs{:});

stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', stat_name, pat.source));
p = struct;
p.reg_defs = reg_defs;
p.levels = levels;
stat = init_stat(stat_name, stat_file, pat.source, p);

for i = 1:n_out
  eval([var_names{i} '=out{i};']);
end

save(stat.file, 'levels', var_names{:});
pat = setobj(pat, 'stat', stat);

