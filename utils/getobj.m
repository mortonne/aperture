function [obj,ind] = getobj(s,f,objname)
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
%   See also setobj, rmobj.

% input checks
if ~exist('s','var')
  error('You must pass a structure containing a list of objects.')
  elseif ~isstruct(s)
  error('s must be a structure.')
  elseif length(s)>1
  error('s cannot be a vector structure.')
  elseif ~exist('f','var')
  error('You must specify a field of s.')
end
if ~exist('objname','var')
  objname = '';
end

% get the list of objects
objs = s.(f);
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
  ind = find(strcmp({objs.name},objname));
  elseif isfield(objs, 'id')
  ind = find(strcmp({objs.id},objname));
  else
  error('Objects do not have identifier field.');
end

% did we find the object we were looking for?
if isempty(ind)
  error('object %s not found.', objname)
end

% get the object
obj = objs(ind);
