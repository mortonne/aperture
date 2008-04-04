function s = setobj(s,f,obj)
%s = setobj(s,f,obj)
%
%SETOBJ - adds an object to the field named f in struct s.  If the
%field does not exist, it is created; if an object with the same
%'name' field already exists, it is replaced; otherwise, the new
%object is appended to the existing objects.

if nargin==3
  if ~isfield(s,f) || isempty(getfield(s,f))
    s = setfield(s,f,obj);
    return
  end
  
  objs = getfield(s,f);
else
  objs = s;
  obj = f;
end

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

% get the fieldnames of the new object and the old objects
fields = fieldnames(obj);
old_fields = fieldnames(objs);

% see which fields are missing from one
[c, newInd, oldInd] = setxor(fields, old_fields);

if ~isempty(c)
  % add fields in obj but not objs
  to_add = setdiff(fields, old_fields);
  if ~isempty(to_add)
    for k=1:length(to_add)
      for j=1:length(objs)
	new(j) = setfield(objs(j), to_add{k}, []);
      end
    end
    objs = new;
  end
  
  % add fields in objs but not obj
  to_add = setdiff(old_fields, fields);
  if ~isempty(to_add)
    for k=1:length(to_add)
      obj = setfield(obj, to_add{k}, []);
    end
  end
end
  
% make sure the fields are in the same order
if length(objs)>0
  obj = orderfields(obj, objs);
end

% put obj in correct place
objs(i) = obj;

if nargin==3
  % change the struct field
  s = setfield(s,f,objs);
else
  s = objs;
end

