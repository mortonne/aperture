function pat = pattern_statmap(pat, reg_defs, f_stat, stat_name, ...
                               n_effects, var_names, varargin)
%PATTERN_STATMAP   Create a statistical map of a pattern.
%
%  Run a statistical test on each sample of a pattern.  You may use any
%  statistics function that follows a certain template.  Results will
%  be saved in a stat object, which contains an array called res. res
%  may be a structure or a numeric arrary with results from the test.
%
%  Currently only supports one output from f_stat, but could be expanded
%  to support multiple outputs and naming of each variable.
%
%  pat = pattern_statmap(pat, reg_defs, f_stat, stat_name, ...)
%
%  INPUTS:
%        pat:  a pattern object.
%
%   reg_defs:  cell array of event bin definitions. See make_event_bins
%              for allowed formats.
%
%     f_stat:  function handle for a function. Must be of the form:
%               [a,b,c,...] = f_stat(x, ...)
%              or
%               [a,b,c,...] = f_stat(x, group, ...)
%              if reg_defs is non-empty.
%              res is a structure or numeric scalar, x is a vector
%              of data for a given channel, sample, and frequency,
%              group is a cell array of factors created from reg_defs.
%              Currently, all outputs of f_stat must be numeric and
%              must be of length n_effects (see below).
%
%  stat_name:  string name of the stat object to create.
%
%  n_effects:  number of effects to be calculated. Default is 1.
%
%  var_names:  cell array of strings containing a name for each output
%              of f_stat. Default is to name the first two outputs "p"
%              and "statistic", and name the others "output3",
%              "output4", etc.
%
%  Additional inputs will be passed to f_stat.
%
%  OUTPUTS:
%        pat:  pattern object with an added stat object.

if ~exist('var_names', 'var')
  var_names = {'p', 'statistic'};
end

if ~exist('n_effects', 'var')
  n_effects = 1;
end

% make the regressors
if ~isempty(reg_defs)
  % load events for this pattern
  events = get_dim(pat.dim, 'ev');
  
  group = cell(1, length(reg_defs));
  for i = 1:length(reg_defs)
    group{i} = make_event_bins(events, reg_defs{i})';
  end
  clear events
else
  group = {};
end

% initialize the stat object
stat_file = fullfile(get_pat_dir(pat, 'stats'), ...
                     objfilename('stat', stat_name, pat.source));
p = struct;
p.reg_defs = reg_defs;
stat = init_stat(stat_name, stat_file, pat.source, p);

fprintf('running %s on ''%s'' pattern...\n', func2str(f_stat), pat.name)

% load the pattern
pattern = get_mat(pat);
[n_events, n_chans, n_samps, n_freqs] = size(pattern);

% check the var names
n_out = nargout(f_stat);
if length(var_names) < n_out
  for i = n_out - length(var_names):n_out
    var_names{i} = sprintf('output%d', i);
  end
elseif length(var_names) > n_out
  var_names = var_names(1:n_out);
end

% initialize the outputs
output = cell(1, n_out);
for i = 1:n_out
  output{i} = NaN(n_effects, n_chans, n_samps, n_freqs);
end

n_tests = n_chans * n_samps * n_freqs;
n = 0;
out = cell(1, n_out);
step = floor(n_tests / 10);
for i = 1:n_chans
  for j = 1:n_samps
    for k = 1:n_freqs
      if mod(n, step) == 0
        fprintf('.')
      end
      
      % get this [1 X events] vector of data
      x = squeeze(pattern(:,i,j,k));
      
      % run the function
      if isempty(group)
        [out{:}] = f_stat(x, varargin{:});
      else
        [out{:}] = f_stat(x, group, varargin{:});
      end
      
      for o = 1:n_out
        output{o}(:,i,j,k) = out{o};
      end
      
      n = n + 1;
    end
  end
end

% save the results
for i = 1:n_out
  eval([var_names{i} '=output{i};']);
end
  
save('-v7.3', stat.file, var_names{:});
pat = setobj(pat, 'stat', stat);

