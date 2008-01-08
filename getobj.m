function obj = getobj(s,f,objname)
%obj = getobj(s,f,objname)

objs = getfield(s,f);
if ~isstruct(objs)
  error('Field is not a struct.');
end

obj = filterStruct(objs, 'strcmp(name, varargin{1})', objname);

if isempty(obj)
  error('no object of that name exists')
end

if exist('field', 'var')
  obj = getfield(obj, field);
end
