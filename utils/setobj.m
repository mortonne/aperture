function s = setobj(s, f, obj)
%SETOBJ   Add an object to a list of objects.
%
%  s = setobj(s, f, obj)
%
%  Adds an object to a subfield of a structure.  If the field does not
%  exist, it is created; if an object with the same identifier field
%  already exists, it is replaced; otherwise, the new object is appended
%  to the existing objects.
%
%  INPUTS:
%        s:  a structure whose subfield you wish to add an object to.
%
%        f:  name of the field of s to add obj.
%
%      obj:  object to be added.  Must have an identifier field
%            recognized by get_obj_name.
%
%  OUTPUTS:
%        s:  modified structure.
%
%  See also addobj, getobj.

% input checks
if ~exist('s','var') || ~isstruct(s)
  error('You must pass a structure.')
elseif ~exist('f','var') || ~ischar(f)
  error('You must pass a field name.')
elseif ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object to add.')
elseif isempty(get_obj_name(obj))
  error('obj must have an identifier field.')
end

% if the field doesn't exist, just set it to obj
if ~isfield(s,f) || isempty(s.(f))
	s.(f) = obj;
	return
end

% check the field
if ~isstruct(s.(f))
  error('Field "%s" does not contain a structure.', f)
elseif any(arrayfun(@(x)(isempty(get_obj_name(x))), s.(f)))
  error('Structure "%s" does not have an identifier field.', f)
end

% update the objects vector with the new object
s.(f) = addobj(s.(f), obj);
