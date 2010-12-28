function exp = recover_obj(exp, obj_dir, obj_path, obj_type, file_stem)
%RECOVER_OBJ   Load an exp structure object from disk.
%
%  exp = recover_obj(exp, obj_dir, obj_path, obj_type, file_stem)
%
%  INPUTS:
%      exp:  an experiment object.
%
%  obj_dir:  directory containing subject pattern objects. The function
%            will attempt to add "obj" variables from all MAT-files in
%            the directory.
%
% obj_path:  type, name pairs in a cell array, gives the path to
%            the object, leaves off the initial 'subj' subjname
%            pair.  Example: {'pat','this_pat_name','stat'}
%
% obj_type:  e.g., 'stat'
%
% file_stem: string of the target filename, leaving off the subj id
%
%  OUTPUTS:
%      exp:  experiment object with the pattern objects added to the
%            appropriate subjects.

% step over each of the subjs and if the file is there, load it.
for i = 1:length(exp.subj)
  filename = fullfile(obj_dir, ...
                      strcat(file_stem, exp.subj(i).id, '.mat')); 
  % if this filename corresponds to a real file, load it
  if exist(filename, 'file')
    obj = getfield(load(filename, obj_type), obj_type);
    exp = setobj(exp, 'subj', exp.subj(i).id, obj_path{:}, obj);
  end
end


