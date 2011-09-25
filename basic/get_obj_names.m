function obj_names = get_obj_names(obj)
%GET_OBJ_NAMES   Get the names of a set of objects of the same type.
%
%  obj_names = get_obj_names(obj)

try
  obj_names = {obj.name};
catch
  if isfield(obj, 'id')
    obj_names = {obj.id};
  elseif isfield(obj, 'dir')
    obj_names = {obj.dir};
  elseif isfield(obj, 'experiment')
    obj_names = {obj.experiment};
  else
    obj_names = repmat({''}, 1, length(obj));
  end
end
