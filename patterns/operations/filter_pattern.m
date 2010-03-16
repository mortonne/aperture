function pat = filter_pattern(pat, varargin)
%FILTER_PATTERN   Average over bins of a pattern.
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
%   event_filter - string for inStruct
%   time_filter  - ''
%   chan_filter  - ''
%   freq_filter  - ''
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
  
  % apply the filters
  pattern = pattern(inds{:});
  
  pat = set_mat(pat, pattern, 'ws');
%endfunction

