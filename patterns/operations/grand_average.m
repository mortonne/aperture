function pat = grand_average(subj, pat_name, res_dir)
%GRAND_AVERAGE   Calculate an average across patterns from multiple subjects.
%
%  pat = grand_average(subj, pat_name, res_dir)
%
%  INPUTS:
%      subj:  vector structure holding information about subjects. Each must
%             contain a pat object named pat_name.
%
%  pat_name:  name of the pattern to concatenate across subjects.
%
%   res_dir:  directory in which to save the new pattern. Default is the same
%             directory the first subject's pattern is saved in.
%
%  OUTPUTS:
%       pat:  

if ~exist('pat_name','var')
  error('You must specify the name of the patterns you want to concatenate.')
  elseif ~exist('subj','var')
  error('You must pass a subj structure.')
  elseif ~isstruct(subj)
  error('subj must be a structure.')
end

% get info from the first subject
subj_pat = getobj(subj(1), 'pat', pat_name);
if ~exist('res_dir','var')
  res_dir = get_pat_dir(subj_pat, 'patterns');
end

% initialize the new pattern
filename = sprintf('pattern_%s_ga.mat', pat_name);
pat_file = fullfile(res_dir, filename);
pat = init_pat(pat_name, pat_file, 'multiple_subjects', subj_pat.params, subj_pat.dim);

% get filenames for all subject patterns
for s=1:length(subj)
	subj_pat = getobj(subj(s), 'pat', pat_name);
	subj_files{s} = subj_pat.file;
end

% load and concatenate all subject patterns
fprintf('calculating grand average for pattern %s...', pat_name)
pattern = getvarallsubj(subj, {'pat', pat_name}, 'pattern', 5);

% average across subjects
pattern = nanmean(pattern,5);
save(pat.file, 'pattern');

pat.dim.splitdim = [];
