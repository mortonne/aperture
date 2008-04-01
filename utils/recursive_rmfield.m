function S = recursive_rmfield(S, vars)
%S = recursive_rmfield(S, vars)


if length(vars)==1
  obj2rm = S.(vars{1});
  files = obj2rm.file;
  if ~iscell(files)
    files = {files};
  end
  
  query = 1;
  for f=1:length(files)
    if query
      promptStr = sprintf('Removing data in %s.  Continue?', obj2rm.file{f});
      if strcmpi(promptStr, 'n')
	break;
      elseif
	S = rmfield(S, vars{1});
      end
    end
elseif length(vars)>1
  
  obj = getobj(S, vars{1}, vars{2});
  obj = recursive_rmfield(obj, vars(3:end));
  S = setobj(S, vars{1}, obj);
end
