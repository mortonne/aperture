function pat = diff_pattern(pat, varargin)
%DIFF_PATTERN   Take differences between elements of a pattern.
%
%  pat = diff_pattern(pat, ...)
%
%  Currently only supports taking difference between two channels.
%  Later, can expand to take pairs of indices (or vals?) along any
%  dimension.
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  modified pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   chans     - [1 X 2] array of channel numbers. Difference will be
%               chans(1) - chans(2).
%   chanlabels - currently unsupported
%   save_mats - if true, and input mats are saved on disk, modified mats
%               will be saved to disk. If false, the modified mats will
%               be stored in the workspace, and can subsequently be
%               moved to disk using move_obj_to_hd. (true)
%   overwrite - if true, existing patterns on disk will be overwritten.
%               (false)
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change. ('')
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% default params
defaults.chans = {};
defaults.chanlabels = {};
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @get_chandiffs, {params}, saveopts);

function pat = get_chandiffs(pat, params)
  pat = move_obj_to_workspace(pat);

  % find the channels
  channels = get_dim_vals(pat.dim, 'chan');
  chan_ind = [find(channels==params.chans(1)) find(channels==params.chans(2))];
  if length(chan_ind)~=2
    error('channels not found.')
  end
  
  % take the difference
  pattern = get_mat(pat);
  pattern = pattern(:,chan_ind(1),:,:) - pattern(:,chan_ind(2),:,:);
  pat = set_mat(pat, pattern);

  % fix the dimension info
  pat.dim.chan = struct('number', params.chans, 'region', '', 'label', ...
                        '');
%endfunction
