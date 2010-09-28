function pat = pattern_statmap(pat, reg_defs, f_stat, stat_name, varargin)
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
%               [res] = f_stat(x, ...)
%              or
%               [res] = f_stat(x, group, ...)
%              if reg_defs is non-empty.
%              res is a structure or numeric scalar, x is a vector
%              of data for a given channel, sample, and frequency,
%              group is a cell array of factors created from reg_defs.
%
%  stat_name:  string name of the stat object to create.
%
%  Additional inputs will be passed to f_stat.
%
%  OUTPUTS:
%        pat:  pattern object with an added stat object.

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
res = cell(1, n_chans, n_samps, n_freqs);
n_tests = prod(size(res));
n = 0;
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
        res{1,i,j,k} = f_stat(x, varargin{:});
      else
        res{1,i,j,k} = f_stat(x, group, varargin{:});
      end
      
      n = n + 1;
    end
  end
end

% collapse from a cell array to an array
% doing this so we can have some preallocation without having
% to make assumptions about the class of the output
res = cell2num(res);

% save the results
save(stat.file, 'res');
pat = setobj(pat, 'stat', stat);

