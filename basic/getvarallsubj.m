function varargout = getvarallsubj(subj, obj_path, var_names, dim, varargin)
%GETVARALLSUBJ   Load a variable from an object from multiple subjects.
%
%  varargout = getvarallsubj(subj, obj_path, var_names, dim, ...)
%
%  Many objects on an exp structure have a "file" field that gives the
%  path to a MAT-file that holds data. This function is designed to
%  export such data into matrices that contain data for all subjects.
%
%  INPUTS:
%       subj:  a structure representing each subject in an experiment.
%
%   obj_path:  cell array giving the path to an object on each subj
%              structure in exp. Form must be:
%               {t1,n1,...}
%              where t1 is an object type (e.g. 'pat', 'stat'),
%              and n1 is the name of an object.
%
%  var_names:  string or cell array of strings with the name(s) of
%              variables to be returned in varargout.
%
%        dim:  an integer or 1 X length(var_names) array of integers
%              specifying which dimension to concatenate along. If a 
%              scalar is passed, it will be used for all variables. 
%              By default, all variables will be concatenated by rows.
%
%  OUTPUTS:
%  varargout:  each output is a matrix of one requested variable,
%              concatenated across subjects along the specified
%              dimension. Output order will be the same as in varnames.
%
%  PARAMS:
%   file_number    - integer specifying which file to load, if obj.file
%                    is a cell array. ([])
%
%  EXAMPLES:
%   % to export the variable named "pcorr" saved in the MAT-file in
%   % a stat object:
%   obj_path = {'pat', 'my_pat_name', 'stat', 'my_stat_name'};
%   pcorr = getvarallsubj(exp.subj, obj_path, {'pcorr'});

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must pass a subj structure.')
end
if ~exist('obj_path', 'var')
  obj_path = {};
end
if ~exist('dim', 'var')
  dim = 1;
end
if ~exist('var_names', 'var')
  error('You must specify which variables you want to load.')
end
if ~iscell(var_names)
  var_names = {var_names};
end
if ~(length(dim)==1 || length(dim)==length(var_names))
  error('dim must either be a scalar or the same length as var_names')
end

% process options
defaults.file_number = [];
params = propval(varargin, defaults);

if length(dim)==1
  % use the same dimension to concatenate all variables
  dim = repmat(dim, 1, length(var_names));
end

% export the objects from the subj vector
objs = getobjallsubj(subj, obj_path);

% initialize output
varargout = cell(1, length(var_names));
for obj = objs
  % use obj type to determine how to load the variables
  try
    obj_type = get_obj_type(obj);
  catch
    obj_type = '';
  end

  if ismember(obj_type, {'ev' 'events'})
    obj_type = 'events';
  elseif ismember(obj_type, {'pat' 'pattern'})
    obj_type = 'pattern';
  end
  
  % load the variables
  if ~isempty(params.file_number)
    % loading one of multiple files
    if ~iscell(obj.file)
      error('params.file_number only makes sense if obj.file is a cell array.')
    end
    % load the specified variables for this file
    temp = load(obj.file{params.file_number}, var_names{:});
    
  elseif iscell(obj.file)
    error('obj.file is a cell array. You must specify a file_number.')
    
  elseif ~isempty(obj_type) && isscalar(var_names) && ...
         strcmp(var_names, obj_type)
    % loading a mat from an object
    temp.(obj_type) = get_mat(obj);
    
  else
    % only one file; load the specified variables
    temp = load(obj.file, var_names{:});
  end
  
  % place the loaded variables in the cell array
  for v = 1:length(var_names)
    % check to see if we got this variable
    if ~isfield(temp, var_names{v})
      continue
    end
    
    % get the variable corresponding to this var_name
    variable = temp.(var_names{v});
    
    % add to the outputs
    if isnumeric(variable) || islogical(variable)
      varargout{v} = cat(dim(v), varargout{v}, variable);
    else
      varargout{v} = cat(dim(v), varargout{v}, {variable});
    end
  end
end

