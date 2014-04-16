function stat = set_stat(stat, varargin)
%SET_STAT  Save variables to a statistics object.
%
%  stat = set_stat(stat, var_name1, var1, var_name2, var2, ...)

large_vars = false;
all_vars = {};
for i = 1:2:length(varargin)
  % move to the specified variable name
  var_name = varargin{i};
  all_vars = [all_vars {var_name}];
  eval([var_name ' = varargin{i+1};'])
  
  % check the size
  w = whos(var_name);

  if exist(stat.file, 'file') || exist([stat.file '.mat'], 'file')
    options = {'-append'};
  else
    options = {};
  end
  
  %fprintf('Variable %s is %.0f bytes\n', var_name, w.bytes)
  if w.bytes > 1900000000
    % huge variable; need different MAT-file format
    % apparently uses some type of compression
    large_vars = true;
    %fprintf('Saving in v7.3 file.\n')
  end
  
  if large_vars
    save('-v7.3', stat.file, var_name, options{:})
  else
    save(stat.file, var_name, options{:})
  end
end

% save the stat object also
obj = stat;
if large_vars
  save('-v7.3', stat.file, 'stat', 'obj', '-append')
else
  save(stat.file, 'stat', 'obj', '-append')  
end

% update the list of variables stored in the file
stat.vars = who('-file', stat.file);

