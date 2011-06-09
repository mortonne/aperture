function s = obj_path2str(varargin)
%OBJ_PATH2STR   Print an object path to a string.
%
%  s = obj_path2str(obj_type1, obj_name1, obj_type2, obj_name2, ...)

s = sprintf('%s/', varargin{:});
s = s(1:end-1);

