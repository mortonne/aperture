function subj = load_obj_all_subj(subj, obj_type, obj_dir)
%LOAD_OBJ_ALL_SUBJ   Load subject objects from disk.
%
%  Useful for recovering a set of objects (e.g. patterns) for each
%  subject, if there is no record on the experiment
%  structure. Currently, only loading of patterns is supported.
%
%  subj = load_obj_all_subj(subj, obj_type, obj_dir)
%
%  INPUTS:
%      subj:  vector of subject objects.
%
%  obj_type:  type of object (e.g. 'pat').
%
%   obj_dir:  main directory in which information related to the objects
%             are stored.
%
%  OUTPUTS:
%      subj:  updated subjects vector with the loaded object.

switch obj_type
  case {'pat' 'pattern'}
    pat_dir = fullfile(obj_dir, 'patterns');
    if ~exist(pat_dir, 'dir')
      error('Pattern directory does not exist: %s', pat_dir)
    end
    
    for i = 1:length(subj)
      d = dir(fullfile(pat_dir, sprintf('pattern*%s.mat', subj(i).id)));
      if isempty(d)
        fprintf('Cannot find pattern file for %s. Skipping...\n', subj(i).id)
        continue
      end
      
      pat = getfield(load(fullfile(pat_dir, d.name), 'obj'), 'obj');
      subj(i) = setobj(subj(i), 'pat', pat);
    end
  otherwise
    error('Object type not supported: %s', obj_type)  
end

