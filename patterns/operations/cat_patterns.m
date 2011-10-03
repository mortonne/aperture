function pat = cat_patterns(pats, dimension, varargin)
%CAT_PATTERNS   Concatenate a set of patterns.
%
%  pat = cat_patterns(pats, dimension, ...)
%
%  INPUTS:
%       pats:  a vector of pat objects.
%
%  dimension:  dimension along which to concatenate the patterns. Can be
%              either a string specifying the name of the dimension (can
%              be: 'ev', 'chan', 'time', 'freq'), or an integer
%              corresponding to the dimension in the pattern matrix.
%
%  OUTPUTS:
%        pat:  pat object with metadata for the new concatenated
%              pattern.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats - if true, mats associated with the new pattern will
%               be saved to disk. If false, modified mats will be stored
%               in the workspace, and can subsequently be moved to disk
%               using move_obj_to_hd. (true)
%   save_as   - name of the concatenated pattern. If all patterns have
%               the same name, defaults to that name; otherwise, the
%               default name is 'cat_pattern'.
%   res_dir   - path to the directory in which to save the new pattern.
%               Default is the same directory as the first pattern in
%               pats.

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

% use the first pattern to set defaults
def_pat = pats(1);
pats_name = unique({pats.name});
if length(pats_name) == 1
  default_pat_name = pats_name{:};
else
  default_pat_name = 'cat_pattern';
end

% options
defaults.save_mats = true;
defaults.save_as = default_pat_name;
defaults.res_dir = get_pat_dir(def_pat);
defaults.verbose = true;
params = propval(varargin, defaults);
pat_name = params.save_as;

% input checks
if ~exist('pats', 'var')
  error('You must pass a vector of pat objects.')
end
if ~exist('dimension', 'var')
  dimension = 2;
end

% parse the dimension input
try
  [dim_name, dim_number] = read_dim_input(dimension);
catch
  if isnumeric(dimension)
    % non-standard dimension; cannot track metadata, but can still
    % concatenate the matrix
    dim_name = '';
    dim_number = dimension;
  else
    error('Invalid dimension.')
  end
end

% print status
if params.verbose
  if length(pats_name) == 1
    fprintf('concatenating "%s" patterns along %s dimension...\n', ...
            pats_name{:}, dim_name)
  else
    fprintf('concatenating patterns along %s dimension...\n', dim_name)
  end
end

% make sure the non-cat dimensions match
pat_sizes = cell(1, length(pats));
for i=1:length(pats)
  full_size = patsize(pats(i).dim);
  pat_sizes{i} = full_size(~ismember(1:length(full_size), dim_number));
end
if ~isequal(pat_sizes{:})
  error('pattern dimensions do not match.')
end

% get a source identifier to set filenames
source = unique({pats.source});
if length(source) > 1
  source = 'multiple';
else
  source = source{:};
end

if params.save_mats
  loc = 'hd';
else
  loc = 'ws';
end

% print names if they are unique; otherwise, print sources
if params.verbose
  sources = {pats.name};
  if ~isunique(sources)
    sources = {pats.source};
  end
end

% concatenate the dim structure
dim = def_pat.dim;
if strcmp(dim_name, 'ev')
  % load each events structure
  if params.verbose
    fprintf('events...')
  end
    
  events = [];
  for i = 1:length(pats)
    if params.verbose
      fprintf('%s ', sources{i})
    end
      
    pat_events = get_mat(pats(i).dim.ev);
    events = cat_structs(events, pat_events);
  end
  if params.verbose
    fprintf('\n')
  end

  % save the concatenated events
  ev_dir = fullfile(params.res_dir, 'events');
  if ~exist(ev_dir)
    mkdir(ev_dir);
  end
  dim.ev.file = fullfile(ev_dir, ...
                         objfilename('events', pat_name, source));
  dim.ev = set_mat(dim.ev, events, loc);
  if strcmp(loc, 'ws')
    dim.ev.modified = true;
  end
  
  % update the ev object
  dim.ev.source = source;
  dim.ev.len = length(events);
elseif ~isempty(dim_name)
  % for non-events dimensions, assume fields are the same and use
  % standard concatenation
  dims = [pats.dim];
  dim.(dim_name) = [dims.(dim_name)];
end

% set the directory to save the pattern
pat_dir = fullfile(params.res_dir, 'patterns');
if ~exist(pat_dir)
  mkdir(pat_dir)
end

% concatenate the pattern
if params.verbose
  fprintf('patterns...')
end
pattern = [];
for i=1:length(pats)
  if params.verbose
    fprintf('%s ', sources{i})
  end
  pattern = cat(dim_number, pattern, get_mat(pats(i)));
end
if params.verbose
  fprintf('\n')
end

% create the new pat object
pat_file = fullfile(pat_dir, ...
                    objfilename('pattern', pat_name, source));
pat = init_pat(pat_name, pat_file, source, def_pat.params, dim);
if params.verbose
  fprintf('pattern "%s" created.\n', pat_name)
end

% save the new pattern
pat = set_mat(pat, pattern, loc);
if strcmp(loc, 'ws')
  pat.modified = true;
end

