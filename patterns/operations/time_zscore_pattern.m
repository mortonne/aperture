function pat = time_zscore_pattern(pat, varargin)
%TIME_ZSCORE_PATTERN   Z-score a pattern over time.
%
%  If the standard deviation for a timeseries is 0, the zscores for that
%  timeseries will be NaN.
%
%  pat = time_zscore_pattern(pat, ...)
%
%  INPUTS:
%      pat:  a pattern object.
%
%  OUTPUTS:
%      pat:  modified pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats  - if true, and input mats are saved on disk, modified
%                mats will be saved to disk. If false, the modified mats
%                will be stored in the workspace, and can subsequently
%                be moved to disk using move_obj_to_hd. (true)
%   overwrite  - if true, existing patterns on disk will be overwritten.
%                (false)
%   save_as    - string identifier to name the modified pattern. If
%                empty, the name will not change. ('')
%   res_dir    - directory in which to save the modified pattern and
%                events, if applicable. Default is a directory named
%                pat_name on the same level as the input pat.

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

% options
defaults = struct;
[params, save_opts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @apply_zscore, {params}, save_opts);


function pat = apply_zscore(pat, params)

  pattern = get_mat(pat);

  % for each timeseries, subtract mean and divide by standard deviation
  rep_ind = [1 1 size(pattern, 3) 1];
  pattern = (pattern - repmat(nanmean(pattern, 3), rep_ind)) ./ ...
            repmat(nanstd(pattern, 0, 3), rep_ind);
  
  pat = set_mat(pat, pattern, 'ws');

