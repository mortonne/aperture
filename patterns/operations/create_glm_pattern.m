function pat = create_glm_pattern(pat, stat_name, varargin)
%CREATE_GLM_PATTERN   Create a pattern from remove_eog_glm output.
%
%  From the results of GLM regression, get the residuals (predicted
%  voltages adjust by the regressors), and put them in a new pattern.
%  The adjusted voltages can then be manipulated and plotted in all of
%  the ways that any other pattern can.
%
%  pat = create_glm_pattern(pat, stat_name, ...)
%
%  INPUTS:
%        pat:  a pattern object.
%
%  stat_name:  name of a stat object attached to pat that contains
%              results of GLM regression (created using runGLM2.m).
%
%  OUTPUTS:
%        pat:  the new pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats - if true, and input mats are saved on disk, modified
%               mats will be saved to disk. If false, the modified mats
%               will be stored in the workspace, and can subsequently
%               be moved to disk using move_obj_to_hd. (true)
%   overwrite - if true, existing patterns on disk will be overwritten.
%               (false)
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change. ('')
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.

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
  error('You must pass a pattern object.')
elseif ~exist('stat_name', 'var') || ~ischar(stat_name)
  error('You must pass the name of the stat object to use.')
end

% set params
defaults.precision = '';
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @get_GLM_pattern, {stat_name, params}, ...
                  saveopts);



function pat = get_GLM_pattern(pat, stat_name, params)
  %get the results of the GLM regression
  stat = getobj(pat, 'stat', stat_name);
  new_pattern = getfield(load(stat.file), 'resid');
  pat = set_mat(pat, new_pattern, 'ws');
