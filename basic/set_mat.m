function obj = set_mat(obj, mat)
%SET_MAT   Update the matrix for an object.
%
%  obj = set_mat(obj, mat)
%
%  INPUTS:
%      obj:  an object.
%
%      mat:  the matrix corresponding to the object.
%
%  OUTPUTS:
%      obj:  the modified object.

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
elseif ~exist('mat','var')
  error('You must pass a matrix to set.')
end

objtype = get_obj_type(obj);

% type-specific checks/changes to obj
switch objtype
  case 'events'
  % update the length field
  obj.len = length(mat);
end

% set the matrix
if isfield(obj, 'mat') && ~isempty(obj.mat)
  % mat is already in memory; overwrite, and mark as modified
  % from the version on file
  obj.mat = mat;
  obj.modified = true;
else
  eval([objtype '=mat;']);
  save(obj.file, objtype)
end
