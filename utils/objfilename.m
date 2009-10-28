function filename = objfilename(obj_type, obj_name, source)
%OBJFILENAME   Construct a standard filename for an object.
%   
%  filename = objfilename(obj_type, obj_name, source)

filename = sprintf('%s_%s_%s.mat', obj_type, obj_name, source);
