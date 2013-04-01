function pat = faster_pattern(pat, varargin)
%FASTER_PATTERN   Remove artifacts using FASTER.
%
%  pat = faster_pattern(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  filtered pattern object, with updated pattern matrix and
%            associated metadata.
%
%  OPTIONS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
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

% options
def.eog_pairs = {[8 126] [25 127] [1 32]};
def.locs_file = 'HCGSN128_eog.loc';
def.epoch_thresh = 150;
def.epoch_chan_thresh = 150;
def.bad_chan_thresh = 12;
def.job_file = '';
[opt, saveopt] = propval(varargin, def);

% mod_pattern handles file management
pat = mod_pattern(pat, @apply_pat_filtering, {opt}, saveopt);

function pat = run_faster(pat, opt)





