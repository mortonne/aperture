function pat = filter_pattern(pat, varargin)
%FILTER_PATTERN   Get a subset of a pattern.
%
%  pat = filter_pattern(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  filtered pattern object, with updated pattern matrix and
%            associated metadata.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_filter - string for inStruct to be applied to the
%                  events structure. See inStruct for details (this
%                  corresponds to the "expr" input argument). ('')
%   time_filter  - range of times in milliseconds to include in the form
%                  [start finish] (the upper bound is not inclusive), or
%                  string for inStruct to be applied to the time
%                  structure. ('')
%   chan_filter  - may be of type:
%                   char    - will be input to inStruct to filter the
%                             channel structure
%                   cellstr - (cell array of strings); a list of channel
%                             labels in include
%                   numeric - array of channel numbers to include
%                  Default is: ''
%   freq_filter  - range of frequencies in Hz to include in the form
%                  [lower_bound upper_bound], or string for inStruct to
%                  be applied to the freq structure. ('')
%   save_mats    - if true, and input mats are saved on disk, modified
%                  mats will be saved to disk. If false, the modified
%                  mats will be stored in the workspace, and can
%                  subsequently be moved to disk using move_obj_to_hd.
%                  (true)
%   overwrite    - if true, existing patterns on disk will be
%                  overwritten. (false)
%   save_as      - string identifier to name the modified pattern. If
%                  empty, the name will not change. ('')
%   res_dir      - directory in which to save the modified pattern and
%                  events, if applicable. Default is a directory named
%                  pat_name on the same level as the input pat.

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

% default params
defaults.event_filter = '';
defaults.time_filter = '';
defaults.chan_filter = '';
defaults.freq_filter = '';
[params, saveopts] = propval(varargin, defaults);

% mod_pattern handles file management
pat = mod_pattern(pat, @apply_pat_filtering, {params}, saveopts);

function pat = apply_pat_filtering(pat, params)
  pattern = get_mat(pat);  

  % convert to old param names
  p = [];
  p.eventFilter = params.event_filter;
  p.timeFilter = params.time_filter;
  p.chanFilter = params.chan_filter;
  p.freqFilter = params.freq_filter;
  
  % get indices corresponding to each filtered dimension
  [pat, inds] = patFilt(pat, p);
  
  % apply the filters to the pattern
  old_size = size(pattern);
  old_size((length(old_size) + 1):4) = 1;
  pattern = pattern(inds{:});
  new_size = size(pattern);
  new_size((length(new_size) + 1):4) = 1;
  
  pat = set_mat(pat, pattern, 'ws');
  clear pattern
  
  % apply the filters to children
  all_ind = repmat({':'}, 1, 4);
  if ~isfield(pat, 'stat')
    return
  end
  
  for i = 1:length(pat.stat)
    stat_file = pat.stat(i).file;
    filename = objfilename('stat', [pat.stat(i).name '_filt'], pat.source);
    new_stat_file = fullfile(get_pat_dir(pat, 'stats'), filename);
    
    vars = whos('-file', stat_file);
    modified = false(1, length(vars));
    for j = 1:length(vars)
      var_name = vars(j).name;
      
      % expanded var size
      var_size = vars(j).size;
      var_size((length(var_size) + 1):4) = 1;
      
      % get dimensions of variable that should be filtered
      to_filter = (old_size ~= new_size) & (old_size == var_size);
      if any(to_filter)
        % load this variable
        s = load(stat_file, var_name);
        
        % get indices for dimensions to change
        var_ind = all_ind;
        var_ind(to_filter) = inds(to_filter);
        
        % filter
        var = s.(var_name);
        var = var(var_ind{:});
        
        % save under the original name
        eval([var_name '=var;']);
        if exist(new_stat_file, 'file')
          save(new_stat_file, var_name, '-append');
        else
          save(new_stat_file, var_name);
        end
        modified(j) = true;
      end
    end
    
    % modify the stat object to point to the new file
    if any(modified)
      pat.stat(i).file = new_stat_file;
    end
  end



