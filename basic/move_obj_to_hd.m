function obj = move_obj_to_hd(obj, overwrite)
%MOVE_OBJ_TO_HD   Move an object from the workspace to harddisk.
%
%  obj = move_obj_to_hd(obj, overwrite)
%
%  Save obj.mat in obj.file as a variable named objtype.  The object's
%  mat is removed, and obj.modified is set to false.
%
%  INPUTS:
%        obj:  an object.
%
%  overwrite:  if true (default), existing files will be overwritten.
%
%  OUTPUTS:
%        obj:  the object.

% input checks
if ~exist('obj', 'var') || ~isstruct(obj)
  error('You must pass an object.')
elseif ~isfield(obj, 'mat') || isempty(obj.mat)
  error('obj must have a "mat" field.')
elseif ~isfield(obj, 'file') || isempty(obj.file)
  error('obj must have a "file" field.')
end
if ~exist('overwrite', 'var')
  overwrite = true;
end

% check if the file already exists
if ~overwrite && exist(obj.file, 'file')
  error('File already exists: %s', obj.file)
end

% get the matrix
mat = get_mat(obj);

% remove the matrix from the object
obj = remove_mat(obj);

% save to disk
obj = set_mat(obj, mat, 'hd');

