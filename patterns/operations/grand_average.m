function pat = grand_average(subj, pat_name, varargin)
%GRAND_AVERAGE   Calculate an average across patterns from multiple subjects.
%
%  Used to calculate an average across subjects for a given pattern
%  type. The pattern indicated by pat_name must have the same dimensions
%  for each subject (except for the events dimension, whose size may
%  vary between subjects).
%
%  pat = grand_average(subj, pat_name, ...)
%
%  INPUTS:
%      subj:  vector structure holding information about subjects. Each
%             must contain a pat object named pat_name.
%
%  pat_name:  name of the pattern to concatenate across subjects.
%
%  OUTPUTS:
%       pat:  new pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_bins   - definition of event bins to average over before
%                  averaging across subjects. See make_event_bins for
%                  bin definition types. Default is to average over all
%                  of each subject's events. ('overall')
%   event_labels - cell array of strings giving a label for each
%                  event_bin. ({})
%   event_levels - cell array of cell arrays of strings giving labels
%                  for each level of the factors specified in
%                  event_bins. ({})
%   dist         - option for distributing jobs when calculating
%                  event_bins. See apply_to_pat for details. (0)
%   save_mats    - if true, and input mats are saved on disk, modified
%                  mats will be saved to disk. If false, the modified
%                  mats will be stored in the workspace, and can
%                  subsequently be moved to disk using move_obj_to_hd.
%                  (true)
%   overwrite    - if true, existing patterns on disk will be
%                  overwritten. (false)
%   save_as      - string identifier to name the modified pattern. If
%                  empty, the name will not change. ('')
%   res_dir      - directory in which to save the new pattern and
%                  events. Default is a directory named pat_name on the
%                  same level as the first subject's pat.

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
if ~exist('pat_name', 'var')
  error('You must specify the name of the patterns you want to concatenate.')
elseif ~exist('subj', 'var')
  error('You must pass a subj structure.')
elseif ~isstruct(subj)
  error('subj must be a structure.')
end

% get info from the first subject
defaults.event_bins = 'overall';
defaults.event_labels = {};
defaults.event_levels = {};
defaults.dist = 0;
defaults.memory = '2g';
[params, saveopts] = propval(varargin, defaults);

saveopts = propval(saveopts, struct, 'strict', false);

fprintf('calculating grand average for pattern "%s"...\n', pat_name)

% bin each subject's events before concatenating
subj = apply_to_pat(subj, pat_name, @bin_pattern, ...
                    {'eventbins', params.event_bins, ...
                     'eventbinlabels', params.event_labels, ...
                     'eventbinlevels', params.event_levels, ...
                    'save_mats', false}, params.dist, ...
                    'memory', params.memory);

% concatenate the subjects
pats = getobjallsubj(subj, 'pat', pat_name);
pat = cat_patterns(pats, 'ev', 'save_mats', false, 'verbose', false);

% average, saving as requested
% the name may stay the same, so must note that the source has changed
pat.source = '';
saveopts.source = 'ga';
saveopts.eventbins = 'label';
pat = bin_pattern(pat, saveopts);

