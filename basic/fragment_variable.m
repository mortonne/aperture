function frag_cell = fragment_variable(file_path, var_name, frag_path, ...
                                       frag_dim, unique_id)
% FRAGMENT_VARIABLE take a variable saved in a file, and carve it up
%      along some dimension, saving the carved pieces to a temporary
%      location and passing back the path to these files.
%
%
%
%


% load the variable
var = load(file_path, var_name);
sz = size(var.(var_name));

grab = cell(1,length(sz));
for i=1:length(grab)
  grab{i} = ':';
end

% step over the specified dimension
for i=1:sz(frag_dim)
  
  grab{frag_dim} = i;

  % grab the specified slice
  frag = var.(var_name)(grab{:});
  
  % save to disk in the frag_path
  fullpath = fullfile(frag_path, ...
                      strcat('temp_',unique_id,'_',var_name, ...
                             '_d',num2str(frag_dim),'_ind',num2str(i)));
  save(fullpath,'frag');
  
  % save path to a cell array
  frag_cell{i} = fullpath;
  % return the cell array

end
% endfunction
