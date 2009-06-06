function mat = get_mat(obj)
%GET_MAT   Load the matrix from an object.
%
%  mat = get_mat(obj)
%
%  If the matrix is saved to disk, obj.file will be loaded.
%  If matrix is stored in the "mat" field, it will be retrieved from
%  that.
%
%  INPUTS:
%      obj:  an object.
%
%  OUTPUTS:
%      mat:  the loaded matrix.

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
elseif ~any(isfield(obj, {'file', 'mat'}))
  error('The object must have a "file" or "mat" field.')
end

objtype = get_obj_type(obj);

if isfield(obj, 'mat') && ~isempty(obj.mat)
  % already loaded; just grab it
  mat = obj.mat;
else
  % must load from file
  if ~exist(obj.file, 'file')
    error('File not found: %s', obj.file)
  end
  
  % load the matrix
  if strcmp(objtype, 'pattern')
    mat = load_pattern(obj);
  else
    s = load(obj.file, objtype);
    mat = s.(objtype);
  end
end

if isempty(mat)
  warning('loading an empty mat.')
end

switch objtype
  case 'events'
  % check the events structure
  if ~isstruct(mat)
    error('events must be a structure.')
  elseif ~isvector(mat)
    error('events must be a vector')
  end

  % make sure we are returning a row vector
  if size(mat,1)>1
    mat = reshape(mat, 1, length(mat));
  end
  
  case 'pattern'
  % sanity check the loaded pattern
  psize = patsize(obj.dim);
  if any(psize(1:ndims(mat))~=size(mat))
    warning('eeg_ana:get_mat:badPatSize', ...
            'size of pattern %s does not match the dim structure.', obj.name)
  end
end
