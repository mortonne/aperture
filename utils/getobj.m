function [obj,ind] = getobj(s,f,objname)
%
%GETOBJ   Retrieve an object from a list of objects.
%
%   OBJ = GETOBJ(S,F,OBJNAME) looks in the field named F in
%   struct S for an object with an "id" or "name" field
%   that matches OBJNAME.  
%
%   OBJ = GETOBJ(S,F) returns the last object added to the
%   list in field F.   
%
%   [OBJ,IND] = GETOBJ(S,F,...) also returns the index
%   where the object was found in F.
%

if ~exist('objname', 'var')
  objname = '';
end

objs = getfield(s,f);
if ~isstruct(objs)
  error('Field is not a struct.');
end

% if name not specified, just get the last object
if isempty(objname)
  obj = objs(end);
  ind = length(objs);
  return
end

% get the identifier field
if isfield(objs, 'name')
  [obj,ind] = filterStruct(objs, 'strcmp(name, varargin{1})', objname);
elseif isfield(objs, 'id')
  [obj,ind] = filterStruct(objs, 'strcmp(id, varargin{1})', objname);
else
  error('Objects do not have identifier field.');
end
ind = find(ind);
