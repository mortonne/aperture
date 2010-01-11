function pat = grand_average(subj, pat_name, varargin)
%GRAND_AVERAGE   Calculate an average across patterns from multiple subjects.
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
%   save_mat - if true, the new pattern will be saved to disk. (true)
%   res_dir  - directory to save the new pattern. (same as subj(1)'s
%              pattern's res_dir)

% input checks
if ~exist('pat_name', 'var')
  error('You must specify the name of the patterns you want to concatenate.')
elseif ~exist('subj', 'var')
  error('You must pass a subj structure.')
elseif ~isstruct(subj)
  error('subj must be a structure.')
end

% get info from the first subject
subj_pat = getobj(subj(1), 'pat', pat_name);
defaults.save_mat = true;
defaults.res_dir = get_pat_dir(subj_pat, 'patterns');
params = propval(varargin, defaults);

% initialize the new pattern
pat_file = fullfile(params.res_dir, objfilename('pattern', pat_name, 'ga'));
pat = init_pat(pat_name, pat_file, 'GrandAverage', subj_pat.params, ...
               subj_pat.dim);

% load and concatenate all subject patterns
fprintf('calculating grand average for pattern %s...', pat_name)
pattern = getvarallsubj(subj, {'pat', pat_name}, 'pattern', 5);

% average across subjects
pattern = nanmean(pattern, 5);

% save the new pattern
if params.save_mat
  pat = set_mat(pat, pattern, 'hd');
else
  pat = set_mat(pat, pattern, 'ws');
end

pat.dim.splitdim = [];

