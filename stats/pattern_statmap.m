function pat = pattern_statmap(pat, reg_defs, f_stat, f_inputs, stat_name, ...
                               n_effects, var_names, varargin)
%PATTERN_STATMAP   Create a statistical map of a pattern.
%
%  Run a statistical test on each sample of a pattern.  You may use any
%  statistics function that follows a certain template.  Results will
%  be saved in a stat object.
%
%  pat = pattern_statmap(pat, reg_defs, f_stat, f_inputs,
%                        stat_name, n_effects, var_names)
%
%  INPUTS:
%        pat:  a pattern object.
%
%   reg_defs:  cell array of event bin definitions. See make_event_index
%              for allowed formats.
%
%     f_stat:  function handle for a function. Must be of the form:
%               [a,b,c,...] = f_stat(x, ...)
%              or
%               [a,b,c,...] = f_stat(x, group, ...)
%              if reg_defs is non-empty.
%
%              x is a vector of data for a given channel, sample, and
%              frequency, and group is a cell array of factors created
%              from reg_defs.
%
%              Each output will be placed into an
%              [effects X channels X time X frequency] or an
%              [1 X channels X time X frequency] array, depending
%              on whether the output from f_stat is a scalar or a
%              vector of length n_effects.
%
%   f_inputs:  cell array of additional inputs to f_stat.
%
%  stat_name:  string name of the stat object to create.
%
%  n_effects:  number of effects to be calculated (i.e. the length of
%              any non-scalar outputs from f_stat). Default is 1.
%
%  var_names:  cell array of strings containing a name for each output
%              of f_stat. Default is {'p', 'statistic', 'res'}.
%
%  OUTPUTS:
%        pat:  pattern object with an added stat object.

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

if ~exist('var_names', 'var')
  var_names = {'p', 'statistic', 'res'};
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
    group{i} = make_event_index(events, reg_defs{i})';
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
  output{i} = cell(1, n_chans, n_samps, n_freqs);
end

n_tests = n_chans * n_samps * n_freqs;
n = 0;
out = cell(1, n_out);
step = floor(n_tests / 100);
for i = 1:n_chans
  for j = 1:n_samps
    for k = 1:n_freqs
      if mod(n, step) == 0 && n ~= 0
        fprintf('.')
      end
      
      % get this [1 X events] vector of data
      x = squeeze(pattern(:,i,j,k));
      
      % run the function
      if isempty(group)
        [out{:}] = f_stat(x, f_inputs{:});
      else
        [out{:}] = f_stat(x, group, f_inputs{:});
      end
      
      for o = 1:n_out
        output{o}{:,i,j,k} = out{o};
      end
      
      n = n + 1;
    end
  end
end
fprintf('\n')

% save the results
for i = 1:n_out
  sample = output{i}{1};
  
  if length(sample) == n_effects
    % get outputs of length n_effects
    output{i} = cat(1, reshape([output{i}{:}], ...
                               [n_effects n_chans n_samps n_freqs]));
  elseif isscalar(sample)
    % convert from cell array to array
    output{i} = cell2num(output{i});
  else
    error('Outputs must have length 1 or n_effects (%d).', n_effects)
  end
  eval([var_names{i} '=output{i};']);
end

save(stat.file, var_names{:});
pat = setobj(pat, 'stat', stat);

