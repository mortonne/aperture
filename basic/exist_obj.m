function tf = exist_obj(s, varargin)
%EXIST_OBJ   Check if an object exists.
%
%  tf = exist_obj(s, obj_type, obj_name, sub_obj_type, sub_obj_name, ...)

% current primitive method: try getting the object, if error, assume it
% doesn't exist
try
  getobj(s, varargin{:});
  tf = true;
catch
  tf = false;
end

