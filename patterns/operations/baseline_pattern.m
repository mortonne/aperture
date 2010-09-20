function pat = baseline_pattern(pat, baselineMS, varargin);
%BASELINE_PATTERN   Apply baseline correction to a pattern.
%
%  Subtracts the mean of the baseline period from each event in a
%  pattern. Used to remove the effect of slow signal drifts.
%
%  pat = baseline_pattern(pat, baselineMS, ...)
%
%  INPUTS:
%         pat:  input pattern object.
%
%  baselineMS:  [2 X 1] array of millisecond values indicating the range
%               of times to include when calculating the baseline for
%               each event.
%
%  OUTPUTS:
%         pat:  modified pattern object.
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

% inputs
if ~exist('pat', 'var')
  error('You must pass a pattern object.')
elseif ~exist('baselineMS', 'var')
  error('You must define the baseline time.')
end

pat = mod_pattern(pat, @apply_baseline, {baselineMS}, varargin{:});

function pat = apply_baseline(pat, baselineMS)

% identify baseline period
times = get_dim_vals(pat.dim, 'time');
base = baselineMS(1) <= times & times < baselineMS(2);

pattern = get_mat(pat);

% within each event, average over times within the baseline
% events X channels X 1 X freq
base_mean = nanmean(pattern(:,:,base,:), 3);

% subtract the baseline
pattern = pattern - repmat(base_mean, [1 1 patsize(pat.dim, 3) 1]);
pat = set_mat(pat, pattern, 'ws');

