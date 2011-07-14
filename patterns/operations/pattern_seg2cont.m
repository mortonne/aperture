function pat = pattern_seg2cont(pat, varargin)
%PATTERN_SEG2CONT   Convert a segmented pattern to continuous form.
%
%  Fold one or more dimensions of a pattern into events. This is
%  generally used to change from segmented to continuous format, i.e.
%  folding in the time dimension, but works with any dimension. The
%  events structure will contain information about the folded-in
%  dimension, allowing statistics to be calculated on both events and
%  other dimension information (e.g. effects of condition and time).
%
%  pat = pattern_seg2cont(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  pattern reshaped to be continuous. Events have an added
%            "time" field giving the time of each event.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   dim_names      - names of dimensions to fold into events. ({'time'})
%   keep_fields    - cell array of strings indicating fields of the
%                    events structure to keep. ({})
%   remove_fields  - cell array of strings indicating fields of the
%                    events structure to remove. ({})
%   save_mats      - if true, and input mats are saved on disk, modified
%                    mats will be saved to disk. If false, the modified
%                    mats will be stored in the workspace, and can
%                    subsequently be moved to disk using move_obj_to_hd.
%                    (true)
%   overwrite      - if true, existing patterns on disk will be
%                    overwritten. (false)
%   save_as        - string identifier to name the modified pattern. If
%                    empty, the name will not change. ('')
%   res_dir        - directory in which to save the modified pattern and
%                    events, if applicable. Default is a directory named
%                    pat_name on the same level as the input pat.

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

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% options
defaults.dim_names = {'time'};
defaults.keep_fields = {};
defaults.remove_fields = {};
[params, saveopts] = propval(varargin, defaults);

% run seg2cont
pat = mod_pattern(pat, @run_seg2cont, {params}, saveopts);

function pat = run_seg2cont(pat, params)

  % load the pattern
  pattern = get_mat(pat);
  events = get_dim(pat.dim, 'ev');
  
  if ~isempty(params.keep_fields)
    f = fieldnames(events);
    f_to_remove = setdiff(f, params.keep_fields);
    events = rmfield(events, f_to_remove);
  end
  if ~isempty(params.remove_fields)
    f = fieldnames(events);
    f_to_remove = union(f, params.remove_fields);
    events = rmfield(events, f_to_remove);
  end
  
  % reshape to merge dimension with events
  dims = 1:4;
  
  for i = 1:length(params.dim_names)
    % move this dim to the front
    pat_size = patsize(pat.dim);
    [dim_name, dim_number] = read_dim_input(params.dim_names{i});
    dim_size = pat_size(dim_number);
    new_order = [dim_number dims(~ismember(dims, dim_number))];
    
    % reshape
    new_shape = [pat_size(1) * dim_size pat_size(2:end)];
    new_shape(dim_number) = 1;
    pattern = reshape(permute(pattern, new_order), new_shape);
    
    % create new events with a field for this dim
    dim_vals = get_dim_vals(pat.dim, dim_name);
    
    new_events = [];
    vals_cell = num2cell(dim_vals);
    for j = 1:pat_size(1)
      these_events = repmat(events(j), 1, dim_size);
      [these_events.(dim_name)] = vals_cell{:};
      new_events = [new_events these_events];
    end
    events = new_events;
    
    % collapse the dim
    switch dim_name
     case 'chan'
      new_dim = struct('number', [], 'label', '');
     case 'time'
      new_dim = init_time();
     case 'freq'
      new_dim = init_freq();
    end
    pat.dim = set_dim(pat.dim, dim_name, new_dim, 'ws');
  end

  % save the original, segmented events
  pat.dim.ev_seg = pat.dim.ev;
  
  % store the new pattern and events
  pat = set_mat(pat, pattern, 'ws');
  pat.dim = set_dim(pat.dim, 'ev', events, 'ws');
  
