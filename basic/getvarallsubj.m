function varargout = getvarallsubj(subj,path,var_names,dim)
%GETVARALLSUBJ   Load a variable from an object from multiple subjects.
%
%  varargout = getvarallsubj(exp,path,var_names,dim)
%
%  Many objects on an exp structure have a "file" field that gives the
%  path to a MAT-file that holds data. This function is designed to
%  export such data into matrices that contain data for all subjects.
%
%  Each variable loaded must be either an array or a cell array.
%
%  INPUTS:
%       subj:  a structure representing each subject in an experiment. 
%
%       path:  cell array giving the path to an object on each subj
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
%              concatenated across subjects along the specified dimension.
%              Output order will be the same as in varnames.
%
%  EXAMPLES:
%   % to export the variable named "pcorr" saved in the MAT-file in
%   % exp.subj.pat.pc.file for a given pat and pc:
%   pcorr = getvarallsubj(exp.subj,{'pat','my_pat_name','pc','my_pc_name'},'pcorr');

if ~exist('dim','var')
  dim = 1;
end
if ~exist('var_names','var')
  error('You must specify which variables you want to load.')
end
if ~iscell(var_names)
  var_names = {var_names};
end
if ~(length(dim)==1 || length(dim)==length(var_names))
  error('dim must either be a scalar or the same length as var_names')
end
if ~exist('path','var')
  path = {};
end
if ~exist('subj','var')
  error('You must pass a subj structure.')
  elseif ~isstruct(subj)
  error('subj must be a structure.')
  elseif ~isfield(subj,'id')
  error('subj must have an id field.')
end

if length(dim)==1
  % use the same dimension to concatenate all variables
  dim = repmat(dim,1,length(var_names));
end

fprintf('Exporting from subjects...\n')

% first make a subjects X variables cell array
var_cell = cell(length(subj), length(var_names));
for s=1:length(subj)
  fprintf('%s\n', subj(s).id)

  % get the object for this subject
  obj = getobj2(subj(s),path);

  if isempty(obj)
    % we couldn't find an object corresponding to that path
    fprintf('Warning: object %s not found.', path{end})
    continue
  end

  % load just the specified variables
  temp = load(obj.file,var_names{:});
  
  % place the loaded variables in the cell array
  for v=1:length(var_names)
    % check to see if we got this variable
    if ~isfield(temp, var_names{v})
      continue
    end
    
    % get the variable corresponding to this var_name
    variable = temp.(var_names{v});

    % see if this is a supported variable
    if ~(isnumeric(variable) || iscell(variable))
      error('Variable %s is not an array.')
    end

    % add to the cell array
    var_cell{s,v} = temp.(var_names{v});
  end
end

% concatenate each variable and add to the outputs
varargout = cell(1,length(var_names));
for v=1:size(var_cell,2)
  % concatenate this variable across subjects
  for s=1:size(var_cell,1)
    varargout{v} = cat(dim(v), varargout{v}, var_cell{s,v});
  end
end
