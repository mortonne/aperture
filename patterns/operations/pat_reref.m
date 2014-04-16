function pat = pat_reref(pat, ref, varargin)
%PAT_REREF   Convert EEG data to use a new reference.
%
%  pat = pat_reref(pat, ref, ...)
%
%  INPUTS:
%     pat:  pattern object.
%
%     ref:  new reference to use:
%            'average' - reference is the average over all channels.
%            52        - channel number to use as reference. If a
%                        vector, the average over all provided channels
%                        will be used.
%            'Pz'      - label of the channel to use as reference. May
%                        be a string or a cell array of strings to
%                        specify multiple channels (averaged to
%                        calculate reference).
%
%  OUTPUTS:
%      pat:  pattern object with new reference.
%
%  OPTIONS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
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

pat = mod_pattern(pat, @apply_reref, {ref}, varargin{:});

function pat = apply_reref(pat, ref)

  pattern = get_mat(pat);

  % get channel to reference to
  if strcmp(ref, 'average')
    % average reference
    ref_chan = nanmean(pattern, 2);
  else
    % some channel or set of channels
    chan_ind = get_dim_ind(pat.dim, 'chan', ref);
    if length(chan_ind) > 1
      % calculate average over multiple channels
      ref_chan = nanmean(pattern(:,chan_ind,:,:), 2);
    else
      ref_chan = pattern(:,chan_ind,:,:);
    end
  end
  
  pattern = pattern - repmat(ref_chan, [1 size(pattern, 2) 1 1]);

  pat = set_mat(pat, pattern, 'ws');
