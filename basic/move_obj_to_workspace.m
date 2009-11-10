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
%        obj:  the object, with the "mat" field set to the loaded
%              matrix.

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
end
if ~exist('overwrite','var')
  overwrite = false;
end

% check if the object exists anywhere
objtype = get_obj_type(obj);
objname = get_obj_name(obj);
if ~exist_mat(obj)
  error('%s object ''%s'' does not have a mat to be loaded.', objtype, objname)
end

% check where the object is currently
loc = get_obj_loc(obj);

if strcmp(loc, 'ws') && ~overwrite
  % we're not going to overwrite from file, so just return
  return
end

% load the mat from disk and add it to obj
mat = get_mat(obj, 'hd');
obj = set_mat(obj, mat, 'ws');

% just loaded it, so it can't be modified
obj.modified = false;

