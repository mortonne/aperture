function objs = addobj(objs, obj)
%ADDOBJ   Add an object to a list of objects.
%
%  objs = addobj(objs, obj)
%
%  INPUTS:
%     objs:  a vector of objects.
%
%      obj:  an object to be added to objs.  If objs contains an object
%            with the same identifier as obj, it will be overwritten.
%            If obj does not match any of the objects in objs, it will
%            be added to the end.
%
%  OUTPUTS:
%     objs:  a vector of objects updated with obj.

% input checks
if ~exist('objs','var')
  error('You must pass a list of objects.')
elseif ~isempty(objs) && ~isvector(objs)
  error('objs must be a vector.')
elseif ~exist('obj','var')
  error('You must pass an object to append.')
elseif length(obj) > 1
  error('obj must be of length one.')
elseif ~isempty(objs) && any(arrayfun(@(x)(isempty(get_obj_name(x))), objs))
  error('objs must have an identifier field.')
elseif ~isempty(obj) && isempty(get_obj_name(obj))
  error('obj must have an identifier field.')
end

% deal with empty array inputs
% dealing with empty arrays wouldn't be necessary if we were more
% careful about object arrays when concatenating subject and pattern
% objects.  Need these lines for now, but may later want empty arrays
% to be a type error.
if isempty(objs) && ~isempty(obj)
  objs = obj;
  return
elseif isempty(obj) && ~isempty(objs)
  return
elseif isempty(objs) && isempty(obj)
  objs = struct;
  return
end

% check if object with this name already exists
obj_name = get_obj_name(obj);
names = arrayfun(@get_obj_name, objs, 'UniformOutput', false);
[tf, i] = ismember(obj_name, names);

% add the new object to the end, and adding necessary fields in the
% process
objs = cat_structs(objs, obj);

% if the added object is new, we're done
if i==0
  return
end

% overwrite the correct old object
objs(i) = objs(end);
objs(end) = [];
