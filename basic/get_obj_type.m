function objtype = get_obj_type(obj)
%GET_OBJ_TYPE   Get the type of an object.
%
%  objtype = get_obj_type(obj)
%
%  Uses the fieldnames of an object to guess which type of object
%  it is. This is a hack to deal with the lack of actual class
%  structure.
%
%  INPUTS:
%      obj:  some object. Can be a pattern or events object.
%
%  OUTPUTS:
%  objtype:  string indicating the type of object.

% input checks
if ~exist('obj', 'var') || ~isstruct(obj)
  error('You must pass an object.')
end

% guess the object type
if isfield(obj, 'type')
  objtype = obj.type;
elseif isfield(obj, 'dim')
  objtype = 'pattern';
elseif isfield(obj, 'len')
  objtype = 'events';
else
  error('Unknown object type.')
end

