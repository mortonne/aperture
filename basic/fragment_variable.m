function frag_cell = fragment_variable(file_path, var_name, frag_path, ...
                                       frag_dim, unique_id)
%FRAGMENT_VARIABLE   Resave a variable in slices.
%
%  Take a variable saved in a file, and carve it up along some
%  dimension, saving the carved pieces to a temporary location and
%  passing back the path to these files.
%
%  frag_cell = fragment_variable(file_path, var_name, frag_path, 
%                                frag_dim, unique_id)
%
%  INPUTS:
%  file_path:  path to a MAT file containing the variable to fragment.
%
%   var_name:  name of the variable to fragment.
%
%  frag_path:  path to save the new variables in.
%
%   frag_dim:  dimension along which to fragment the variable.
%
%  unique_id:  identifier for this variable.
%
%  OUTPUTS:
%  frag_cell:  cell array with paths to MAT files containing each slice;
%              the slice will be a variable named "frag".

if ~exist(frag_path, 'dir')
  mkdir(frag_path)
end

% load the variable
var = load(file_path, var_name);
sz = size(var.(var_name));

grab = repmat({':'}, 1, length(sz));

% step over the specified dimension
for i = 1:sz(frag_dim)
  grab{frag_dim} = i;

  % grab the specified slice
  frag = var.(var_name)(grab{:});
  
  % save to disk in the frag_path
  fullpath = fullfile(frag_path, ...
                      strcat('temp_',unique_id,'_',var_name, ...
                             '_d',num2str(frag_dim),'_ind',num2str(i)));
  save(fullpath, 'frag');
  
  % save path to a cell array
  frag_cell{i} = fullpath;
end

