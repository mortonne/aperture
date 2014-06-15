function pat = bin_pat_all_subj(subj, pat_name, varargin)
%BIN_PAT_ALL_SUBJ   Create a pattern with average subject patterns.
%
%  Used to average over events for each subject, then concatenate
%  all subjects into one pattern. Useful for preparing data for
%  analysis of group-level statistics.
%
%  pat = bin_pat_all_subj(subj, pat_name, ...)
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
%  OPTIONS:
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
if ~isstruct(subj)
  error('subj must be a structure.')
end

% get info from the first subject
def.event_bins = 'overall';
def.event_labels = {};
def.event_levels = {};
def.dist = 0;
def.memory = '3G';
def.walltime = '00:30:00';
[opt, save_opts] = propval(varargin, def);

def = [];
def.save_mats = false;
def.save_as = get_obj_name(getobj(subj(1), 'pat', pat_name));
def.verbose = false;
save_opts = propval(save_opts, def, 'strict', false);

fprintf('calculating subject averages for pattern "%s"...\n', pat_name)

% bin each subject's events before concatenating
subj = apply_to_pat(subj, pat_name, @bin_pattern, ...
                    {'eventbins', opt.event_bins, ...
                     'eventbinlabels', opt.event_labels, ...
                     'eventbinlevels', opt.event_levels, ...
                    'save_mats', false}, opt.dist, ...
                    'memory', opt.memory);

% concatenate the subjects
pats = getobjallsubj(subj, 'pat', pat_name);
pat = cat_patterns(pats, 'ev', save_opts);

