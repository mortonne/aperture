function obj = move_obj_to_workspace(obj, overwrite)
%MOVE_OBJ_TO_WORKSPACE   Load a saved object file, and keep in memory.
%
%  obj = move_obj_to_workspace(obj, overwrite)
%
%  INPUTS:
%        obj:  an object.
%
%  overwrite:  boolean.  If true, if the object is already in the
%              workspace, it will be replaced by the version on disk.
%              Default: false
%
%  OUTPUTS:
%        obj:  the object, with the "mat" field set to the loaded matrix.

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
elseif ~isfield(obj, 'file') || isempty(obj.file)
  error('obj must have a "file" field.')
end
if ~exist('overwrite','var')
  overwrite = false;
end

if ~overwrite && isfield(obj, 'mat') && ~isempty(obj.mat)
  % nothing to do
  return
end

% load the object (assumed to have the same name as objtype)
objtype = get_obj_type(obj);
load(obj.file, objtype);

% set to the mat field
obj.mat = eval(objtype);

% just loaded it, so it can't be modified
obj.modified = false;
