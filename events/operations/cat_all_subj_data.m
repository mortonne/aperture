function exp = cat_all_subj_data(exp, obj_path, res_dir)
%CAT_ALL_SUBJ_DATA   Concatenate data structures from all subjects.
%
%  exp = cat_all_subj_data(exp, obj_path, res_dir)
%
%  INPUTS:
%       exp:  an experiment object.
%
%  obj_path:  cell array giving the path to an object on each subj
%              structure in exp. Form must be:
%               {t1,n1,...}
%             where t1 is an object type (e.g. 'pat', 'stat'),
%             and n1 is the name of an object.
%
%   res_dir:  directory where the concatenated events structure will be
%             saved.  Default is the directory where the first subject's
%             stats are saved.
%
%  OUTPUTS:
%      exp:  experiment object with an added stat object.

% input checks
if ~exist('exp', 'var')
  error('You must pass an experiment object.')
elseif ~exist('obj_path', 'var')
  error('You must specify the path to the stat object.')
end
stat = getobj(exp.subj(1), obj_path{:});
if ~exist('res_dir', 'var')
  res_dir = fileparts(stat.file);
end

% export all of the stat objects
temp = getvarallsubj(exp.subj, obj_path, {'data'}, 1);

% concatenate
data = [];
for i=1:length(temp)
  data = concatData(data, temp{i});
end

% create a stat object for the concatenated data
stat_name = obj_path{end};
stat_file = fullfile(res_dir, objfilename('stat', stat_name, exp.experiment));
stat = init_stat(stat_name, stat_file, 'multiple', stat.params);
save(stat.file, 'data')

% add the new stat object to the experiment object
exp = setobj(exp, 'stat', stat);
