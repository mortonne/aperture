function objname = get_obj_name(obj)
%GET_OBJ_NAME   Get the name of an object.
%
%  objname = get_obj_name(obj)
%
%  INPUTS:
%      obj:  some object.  Must have an identifier field.
%
%  OUTPUTS:
%  objname:  object identifier.

if length(obj) > 1
  error('Can only get name of one object.')
end

% look for matching fields
try
  objname = obj.name;
catch
  if isfield(obj, 'id')
    objname = obj.id;
  elseif isfield(obj, 'experiment')
    objname = obj.experiment;
  elseif isfield(obj, 'dir')
    % if no other identifier, use the directory
    objname = obj.dir;
  else
    objname = '';
  end
end
