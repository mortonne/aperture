function exp = cat_all_subj_data(exp, obj_path, varargin)
%CAT_ALL_SUBJ_DATA   Concatenate data structures from all subjects.
%
%  exp = cat_all_subj_data(exp, obj_path, ...)
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
%
%  OPTIONS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   res_dir        - directory where the concatenated events structure
%                    will be saved. 
%       (fileparts(getfield(getobj(exp.subj(1), obj_path{:}), 'file')))
%   scalar_fields  - fields that should be a scalar (the unique value
%                    over all subjects), rather than concatenated over
%                    subjects. ({'listLength'})
%   scalar_include - if true, only the fields in scalar_fields will be
%                    scalarized; if false, all other fields will be
%                    scalarized. (true)

% backward compatibility
if length(varargin) == 1 && ischar(varargin{1})
  % assume this is the old calling signature, change to match the new
  % one. Case of setting res_dir list-style and also setting options is
  % not supported, since this shouldn't be the case for legacy code
  varargin = {'res_dir' varargin{1}};
end

% options
stat = getobj(exp.subj(1), obj_path{:});
def.res_dir = fileparts(stat.file);
def.scalar_fields = {'listLength'};
def.scalar_include = true;
opt = propval(varargin, def);

% input checks
if ~exist('exp', 'var')
  error('You must pass an experiment object.')
elseif ~exist('obj_path', 'var')
  error('You must specify the path to the stat object.')
end

% export all of the stat objects
temp = getvarallsubj(exp.subj, obj_path, {'data'}, 1);

% concatenate
data = [];
for i = 1:length(temp)
  data = cat_data(data, temp{i}, opt.scalar_fields, opt.scalar_include);
end

% create a stat object for the concatenated data
stat_name = obj_path{end};
stat_file = fullfile(opt.res_dir, objfilename('stat', stat_name, ...
                                              exp.experiment));
stat = init_stat(stat_name, stat_file, 'multiple', stat.params);
save(stat.file, 'data')

% add the new stat object to the experiment object
exp = setobj(exp, 'stat', stat);
