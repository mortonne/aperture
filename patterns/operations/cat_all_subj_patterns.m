function pat = cat_all_subj_patterns(subj, pat_name, dimension, varargin)
%CAT_ALL_SUBJ_PATTERNS   Concatenate subject patterns into one pattern.
%
%  pat = cat_all_subj_patterns(subj, pat_name, dimension, ...)
%
%  INPUTS:
%       subj:  a vector of subject objects.
%
%   pat_name:  name of the pattern to concatenate.
%
%  dimension:  the dimension to concatenate along.
%
%  OUTPUTS:
%        pat:  new pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_filter - input to filterStruct to get a subset of events
%                before concatenating. ('')
%   event_bins - input to make_event_bins to average over events before
%                concatenating across subjects. ({})
%   dist       - flag for applying event bins in parallel (0=serial,
%                1=distributed, 2=parallel). (0)
%   save_mats  - if true, mats associated with the new pattern will
%                be saved to disk. If false, modified mats will be stored
%                in the workspace, and can subsequently be moved to disk
%                using move_obj_to_hd. (true)
%   save_as    - name of the concatenated pattern. If all patterns have
%                the same name, defaults to that name; otherwise, the
%                default name is 'cat_pattern'.
%   res_dir    - path to the directory in which to save the new pattern.
%                Default is the same directory as the first pattern in
%                pats.

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
defaults.event_filter = '';
defaults.event_bins = {};
defaults.dist = 0;
[params, save_opts] = propval(varargin, defaults);

% apply filtering and binning
if ~isempty(params.event_filter) || ~isempty(params.event_bins)
  subj = apply_to_pat(subj, pat_name, @prep_pattern, ...
                      {params.event_filter, params.event_bins}, params.dist);
end

% get patterns from all subjects
pats = getobjallsubj(subj, {'pat', pat_name});

% concatenate
pat = cat_patterns(pats, dimension, save_opts);


function pat = prep_pattern(pat, event_filter, event_bins)

  if ~isempty(event_filter)
    pat = filter_pattern(pat, 'event_filter', event_filter, ...
                         'save_mats', false, 'verbose', false);
  end
  if ~isempty(event_bins)
    pat = bin_pattern(pat, 'eventbins', event_bins, ...
                         'save_mats', false, 'verbose', false);
  end
  

