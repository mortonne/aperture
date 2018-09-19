function subj = export_pattern(subj, pat_name, out_dir)
%EXPORT_PATTERN   Export a pattern to a self-contained MAT-file.
%
%  Patterns are often saved with one file for the pattern itself, and
%  individual files containing metadata for the other pattern
%  dimensions. This can save space by allowing metadata to be shared
%  between different patterns, but can make the patterns less
%  portable. This script saves a pattern to a self-contained MAT-file
%  with all associated metadata.
%
%  subj = export_pattern(subj, pat_name, out_dir)
%
%  INPUTS:
%      subj:  subject to process.
%
%  pat_name:  name of a pattern object.
%
%   out_dir:  path to directory to output patterns. Each pattern
%             and all associated metadata will be saved in one 
%             MAT-file, as [out_dir]/[pat_name]_[subject].mat
%
%  OUTPUTS:
%      subj:  output subject (no changes are made).
%
%  EXAMPLE:
%  % export the 'volt' pattern for all subjects
%  apply_to_subj(exp.subj, @export_pattern, {'volt', '~/results'})

pat = getobj(subj, 'pat', pat_name);
pat = move_obj_to_workspace(pat);
dims = {'ev' 'chan' 'time' 'freq'};
for i = 1:length(dims)
    pat.dim.(dims{i}) = move_obj_to_workspace(pat.dim.(dims{i}));
end
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

filepath = fullfile(out_dir, sprintf('%s_%s.mat', pat_name, subj.id));
save(filepath, 'pat');
