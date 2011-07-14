function dest = transfer_obj(src, dest, obj_path, varargin)
%TRANSFER_OBJ   Transfer an object from one experiment to another.
%
%  exp = transfer_obj(src, dest, obj_path, ...)
%
%  INPUTS:
%       src:  source experiment with the object to be transferred.
%
%      dest:  experiment to move the object to.
%
%  obj_path:  path to the object in objtype, objname pairs.
%
%  OUTPUTS:
%      exp:  the dest experiment with the added object from src.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   path_base - base that the obj_path is relative to:
%                'exp'  - the object is directly attached to the
%                         experiment
%                'subj' - the object is attached to every subject.
%                         (default)
%   repstr    - cell array of string pairs, where the first is the
%               string to replace, and the second is the string to
%               replace it with. Used to change all strings on the
%               object before moving it (e.g. to fix paths). ({})

% options
defaults.path_base = 'subj';
defaults.repstr = {};
params = propval(varargin, defaults);

switch params.path_base
 case 'exp'
  dest = run_transfer(src, dest, obj_path, params);  
  
 case 'subj'
  for i = 1:length(dest.subj)
    % get the corresponding source subject
    if ~exist_obj(src, 'subj', dest.subj(i).id)
      fprintf('Warning: Subject %s does not exist on src.\n')
      continue
    end
    src_subj = getobj(src, 'subj', dest.subj(i).id);
    dest.subj(i) = run_transfer(src_subj, dest.subj(i), obj_path, params);
  end
end


function dest = run_transfer(src, dest, obj_path, params)

  % grab the object
  if ~exist_obj(src, obj_path{:})
    fprintf('Warning: object %s does not exist on %s.\n', ...
            obj_path{end}, get_obj_name(src))
  end
  obj = getobj(src, obj_path{:});
  
  % recursively replace strings
  if ~isempty(params.repstr)
    obj = struct_strrep(obj, params.repstr{:});
  end

  % set the object
  dest = setobj(dest, obj_path{1:end-1}, obj);
  