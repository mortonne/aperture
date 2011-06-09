function parent = get_obj_parent(obj)
%GET_OBJ_PARENT   Get the name of an object's parent.
%
%  parent = get_obj_parent(obj)

if isfield(obj, 'source')
  parent = obj.source;
else
  parent = '';
end

