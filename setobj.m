function s = setobj(s,f,obj)
%s = setobj(s,f,obj)
%
%SETOBJ - adds an object to the field named f in struct s.  If the
%field does not exist, it is created; if an object with the same
%'name' field already exists, it is replaced; otherwise, the new
%object is appended to the existing objects.


if ~isfield(s,f)
  s = setfield(s,f,obj)
  return
end

objs = getfield(s,f);

if ~isstruct(objs)
  error('Field is not a struct.');
end

% check if object with this name already exists
if isfield(obj, 'name')
  i = find(inStruct(objs, 'strcmp(name, varargin{1})', obj.name));
elseif isfield(obj, 'id')
  i = find(inStruct(objs, 'strcmp(id, varargin{1})', obj.id));
else
  i = [];
end

if isempty(i)
  i = length(objs) + 1;
end

% if other objects exist, make sure fields are in same order
if length(objs)>0
  obj = orderfields(obj, objs);
end

% put obj in correct place, change the struct field
objs(i) = obj;
s = setfield(s,f,objs);

