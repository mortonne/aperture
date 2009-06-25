function objname = get_obj_name(obj)
%GET_OBJ_NAME   Get the name of an object.
%
%  objname = get_obj_name(obj)
%
%  INPUTS:
%      obj:  some object.  Must have an identifier field.
%
%  OUTPUTS:
%  objname:  object identifier.

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
end

% get the name; could be in a couple of different fields
if isfield(obj, 'name')
  objname = obj.name;
elseif isfield(obj, 'id')
  objname = obj.id;
elseif isfield(obj, 'experiment')
  objname = obj.experiment;
elseif isfield(obj, 'dir')
  % if no other identifier, use the directory
  objname = obj.dir;
else
  objname = '';
end

% sanity check the name
if ~ischar(objname)
  disp(objname)
  error('Object name must be a string.')
end
