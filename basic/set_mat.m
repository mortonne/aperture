function obj = set_mat(obj, mat, loc)
%SET_MAT   Update the matrix for an object.
%
%  obj = set_mat(obj, mat, loc)
%
%  INPUTS:
%      obj:  an object.
%
%      mat:  the matrix (or other type of data) corresponding to the
%            object.
%
%      loc:  location where the mat should be stored.  Can be:
%             'hd' - save to a MAT-file.  obj.file must be
%                    defined.
%             'ws' - store in the workspace, in obj.mat
%            If loc is not specified, it will default to 'workspace'
%            if obj.mat is not empty or if obj.file is undefined.
%
%  OUTPUTS:
%      obj:  the modified object.

% input checks
if ~exist('obj','var') || ~isstruct(obj)
  error('You must pass an object.')
elseif ~exist('mat','var')
  error('You must pass a matrix to set.')
end
if ~exist('loc', 'var')
  if (isfield(obj, 'mat') && ~isempty(obj.mat)) || ...
        (~isfield(obj, 'file') || isempty(obj.file))
    loc = 'ws';
  else
    loc = 'hd';
  end
end
if ~isfield(obj, 'modified')
  obj.modified = false;
end

objtype = get_obj_type(obj);

% type-specific checks/changes to obj
switch objtype
 case {'ev' 'events' 'chan' 'time' 'freq'}
  % update the length field
  obj.len = length(mat);
end

switch loc
 case 'hd'
  % save the mat to disk
  if ~isfield(obj, 'file') || isempty(obj.file)
    error('obj.file is not specified.')
  end
  
  % deal with split files
  if ~iscell(obj.file)
    obj_file = {obj.file};
    split = false;
  else
    split = true;
    obj_file = obj.file;
    split_dim = obj.dim.splitdim;
    full_mat = mat;
    all_ind = repmat({':'}, 1, ndims(mat));
  end

  for i = 1:length(obj_file)
    if split
      ind = all_ind;
      ind{split_dim} = i;
      mat = full_mat(ind{:});
    end
    
    eval([objtype '=mat;']);
    clear mat
    % check the size
    w = whos(objtype);

    if w.bytes > 1900000000
      % huge variable; need different MAT-file format
      % apparently uses some type of compression
      save('-v7.3', obj_file{i}, objtype, 'obj')
    else
      % normal MAT-file will do
      save(obj_file{i}, objtype, 'obj')
    end
  end
  obj.modified = false;
  obj.mat = [];
  
 case 'ws'
  % just add it to the mat field
  obj.mat = mat;
  obj.modified = true;
  
 otherwise
  error('loc must be either "hd" or "ws".')
end

