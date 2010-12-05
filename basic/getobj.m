function [obj, ind] = getobj(s, varargin)
%GETOBJ   Retrieve an object from a list of objects.
%
%  INPUTS:
%         s:  a structure whose subfield you wish to retrieve an object
%             from.
%
%         f:  name of a subfield of s containing a list of objects.
%
%  obj_name:  name of the object to get.
%
%  OUTPUTS:
%       obj:  the specified object.
%
%       ind:  index of the object in the list.
%
%  [obj, ind] = getobj(s, f, obj_name)
%
%  Gets an object from a list of objects stored in subfield f
%  of structure s.
%
%  [obj, ind] = getobj(s, f1, obj_name1, f2, obj_name2, ...)
%
%  Retrieves objects recursively.
%
%  EXAMPLE:
%   % get a pat object named "voltage" from subj "LTP001"
%   pat = getobj(exp, 'subj', 'LTP001', 'pat', 'voltage');
%
%  See also setobj, rmobj.

% input checks
if ~exist('s','var') || ~isstruct(s)
  error('You must pass a structure.')
elseif length(s) > 1
  error('Structure must be of length 1.')
elseif length(varargin) < 2
  error('Not enough input arguments.')
end

% get the arguments for this call
[f, obj_name] = varargin{1:2};
varargin(1:2) = [];

if ~ischar(f)
  error('You must pass a field name.')
elseif ~isfield(s, f)
  error('Structure does not have field: %s.', f)
elseif ~ischar(obj_name)
  error('obj_name must be a string.')
end

% get the list of objects
objs = s.(f);

% check the objects
if ~isstruct(objs)
  error('Field "%s" does not contain a structure.', f);
end

% search for the matching object
ind = [];
for i=1:length(objs)
  %if strcmp(obj_name, get_obj_name(objs(i)))
  this_obj_name = get_obj_name(objs(i));
  match = regexp(this_obj_name, obj_name, 'match');
  if strcmp(this_obj_name, match)
    ind = i;
    break
  end
end

if isempty(ind)
  error('Object %s not found.', obj_name)
end

% % get the identifier field
% names = arrayfun(@get_obj_name, objs, 'UniformOutput', false);
% if all(cellfun(@isempty, names))
%   error('Structure "%s" does not have an identifier field.', f)
% end

% % find the object with the name
% [tf, loc] = ismember(obj_name, names);
% ind = nonzeros(loc);

% if isempty(ind)
%   error('Object %s not found.', obj_name)
% elseif length(ind) > 1
%   error('More than one object found matching %s.', obj_name)
% end

% get the object
obj = objs(ind);

if ~isempty(varargin)
  % we have more work to do
  [obj, ind] = getobj(obj, varargin{:});
end
