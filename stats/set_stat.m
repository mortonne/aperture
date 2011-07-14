function set_stat(stat, varargin)
%SET_STAT  Save variables to a statistics object.
%
%  set_stat(stat, var_name1, var1, var_name2, var2, ...)

for i = 1:2:length(varargin)
  % move to the specified variable name
  var_name = varargin{i};
  eval([var_name ' = varargin{i+1};'])
  
  % check the size
  w = whos(var_name);

  if exist(stat.file, 'file') || exist([stat.file '.mat'], 'file')
    options = {'-append'};
  else
    options = {};
  end
  
  if w.bytes > 1900000000
    % huge variable; need different MAT-file format
    % apparently uses some type of compression
    save('-v7.3', stat.file, var_name, options{:})
  else
    % normal MAT-file will do
    save(stat.file, var_name, options{:})
  end
end

