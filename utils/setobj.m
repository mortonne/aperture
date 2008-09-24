function s = setobj(s,f,obj)
%SETOBJ   Add an object to a list of objects.
%   S = SETOBJ(S,F,OBJ) adds an object OBJ to the field named 
%   F in struct S.  If the field does not exist, it is created; 
%   if an object with the same "name" or "id" field already 
%   exists, it is replaced; otherwise, the new object is appended 
%   to the existing objects.
%
%   See also recursive_setobj, getobj.
%

if nargin==3
	if ~isfield(s,f) || isempty(s.(f))
		s.(f) = obj;
		return
	end

	objs = s.(f);
else
	objs = s;
	obj = f;
	keyboard
	if isempty(objs)
    s = obj;
    return
  end
end

if ~isstruct(objs)
	error('Field is not a struct.');
end

% check if object with this name already exists
if isfield(obj, 'name') & isfield(objs, 'name')
	i = find(inStruct(objs, 'strcmp(name, varargin{1})', obj.name));
elseif isfield(obj, 'id') & isfield(objs, 'id')
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
		for j=1:length(objs)
			newobj = objs(j);
			for k=1:length(to_add)
				newobj.(to_add{k}) = [];
			end
			newobjs(j) = newobj;
		end
		objs = newobjs;
	end

	% add fields in objs but not obj
	to_add = setdiff(old_fields, fields);
	if ~isempty(to_add)
		for k=1:length(to_add)
			obj.(to_add{k}) = [];
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
	s.(f) = objs;
else
	s = objs;
end
