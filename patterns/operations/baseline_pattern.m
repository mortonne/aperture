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

