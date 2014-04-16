function mat = get_mat(obj, loc)
%GET_MAT   Load the matrix from an object.
%
%  mat = get_mat(obj, loc)
%
%  INPUTS:
%      obj:  an object.
%
%      loc:  location from which to load the matrix; can be:
%             'ws' - workspace (load from obj.mat)
%             'hd' - hard drive (load from obj.file)
%            If not specified, and the matrix is saved both in workspace
%            and hard drive, workspace takes precendence.
%
%  OUTPUTS:
%      mat:  the loaded matrix.

% input checks
if ~exist('obj', 'var') || ~isstruct(obj)
  error('You must pass an object.')
end

objname = get_obj_name(obj);
objtype = get_obj_type(obj);

% check if there is an associated matrix
if ~exist_mat(obj)
  error('%s object ''%s'' has no matrix.', objtype, objname)
end

if ~exist('loc', 'var') || isempty(loc)
  loc = get_obj_loc(obj);
end

% load the matrix
if strcmp(loc, 'ws')
  % already loaded; just grab it
  mat = obj.mat;
elseif strcmp(loc, 'hd')
  % make sure the file extension is there
  if iscellstr(obj.file)
    for i = 1:length(obj.file)
      [pathstr, name, ext] = fileparts(obj.file{i});
      if isempty(ext)
        obj.file{i} = [obj.file{i} '.mat'];
      end
    end
    obj_file = obj.file{1};
  else
    [pathstr, name, ext] = fileparts(obj.file);
    if isempty(ext)
      obj.file = [obj.file '.mat'];
    end
    obj_file = obj.file;
  end
  
  % must load from file
  if ~exist(obj_file, 'file')
    error('File not found: %s', obj_file)
  end
  
  % get the correct variable name
  if ismember(objtype, {'ev' 'events'})
    var_names = who('-file', obj.file);    
    names = {'ev' 'events'};
    match = find(ismember(names, var_names));
    objtype = names{match(1)};
  elseif strcmp(objtype, 'pat')
    objtype = 'pattern';
  end
    
  if strcmp(objtype, 'pattern') && isfield(obj.dim, 'splitdim') ...
        && ~isempty(obj.dim.splitdim)
    % concatenate along the split dimension to reform the pattern
    mat = NaN(patsize(obj.dim));
    all_ind = repmat({':'}, 1, ndims(mat));
    for i = 1:length(obj.file)
      % load this slice
      s = load(strtrim(obj.file{i}), 'pattern');
      
      % add it to the matrix
      ind = all_ind;
      ind{obj.dim.splitdim} = i;
      mat(ind{:}) = s.pattern;
    end
    
  else
    % load the matrix
    if strcmp(objtype, 'pattern')
      s = whos('-file', obj.file, objtype);
      if s.bytes > 200000000
        % print status if loading more than 200 Mb
        fprintf('Reading pattern file %s ...\n', strtrim(obj.file));
      end
    end
    mat = getfield(load(strtrim(obj.file), objtype), objtype);
  end
  
else
  error('Unknown location type: %s', loc)
end

% run sanity checks on the loaded matrix
if isempty(mat)
  warning('loading an empty mat.')
end

bad_obj_size = false;
switch objtype
 case {'ev' 'events'}
  % check the events structure
  if ~isstruct(mat)
    error('events must be a structure.')
  elseif ~isvector(mat) && ~isempty(mat)
    error('events must be a vector')
  end

  % make sure we are returning a row vector
  if size(mat, 1) > 1
    mat = reshape(mat, 1, length(mat));
  end
  
  % check the size
  bad_obj_size = ~(length(mat)==obj.len);
  
 case 'pattern'
  % sanity check the loaded pattern
  try
    psize = patsize(obj.dim);
    if any(psize(1:ndims(mat))~=size(mat))
      bad_obj_size = true;
    end
  catch
    warning('Pattern dimensions information is corrupted.')
  end
end

if bad_obj_size
  warning('eeg_ana:get_mat:badObjSize', ...
          'size of %s object "%s" does not match the metadata.', ...
          objtype, obj.name)
end

