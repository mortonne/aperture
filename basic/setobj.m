function s = setobj(s, varargin)
%SETOBJ   Add an object to a list of objects.
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
%  s = setobj(s, f, obj)
%
%  Adds an object to a subfield of a structure.  If the field does not
%  exist, it is created; if an object with the same identifier field
%  already exists, it is replaced; otherwise, the new object is appended
%  to the existing objects.
%
%  s = setobj(s, f1, obj_name1, f2, obj_name2, ... f, obj)
%
%  Add an object to an arbitrarily nested structure.  Each fieldname,
%  objname pair climbs the hierarchy.  The last two arguments are the
%  fieldname and object to be added to the top.
%
%  EXAMPLES:
%   s.a = struct('name', {'x', 'y'}, 'prop', {1, 2});
%   % add a new object "z"
%   s = setobj(s, 'a', struct('name', 'z', 'prop', 3));
%   % overwrite the existing object "y"
%   s = setobj(s, 'a', struct('name', 'y', 'prop', 10));
%
%   % make an empty ev object and add to subject LTP001
%   ev = init_ev('my_events');
%   exp = setobj(exp, 'subj', 'LTP001', 'ev', ev);
%
%  See also addobj, getobj.

% input checks
if ~exist('s','var') || ~isstruct(s)
  error('You must pass a structure.')
end
if length(varargin) < 2
  error('Not enough input arguments.')
elseif length(varargin) > 2
  % we have a field and an object name
  [f, obj_name] = varargin{1:2};
  
  % call setobj recursively until we return an object
  obj = getobj(s, f, obj_name);
  obj = setobj(obj, varargin{3:end});
else
  % we just have a fieldname and an object
  [f, obj] = varargin{1:2};
end

% input checks
if ~ischar(f)
  error('Field name must be a string.')
elseif ~isstruct(obj)
  error('Object must be a structure.')
elseif isempty(get_obj_name(obj))
  error('Object must have an identifier field.')
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
