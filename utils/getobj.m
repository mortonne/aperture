function [obj,ind] = getobj(s,f,objname)
%obj = getobj(s,f,objname)

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
