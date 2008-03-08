function S = recursive_setobj(S, vars)
%S = recursive_strrep(S, repStr)

if length(vars)==2
  S = setobj(S, vars{1}, vars{2});
elseif length(vars)>2
  
  obj = getobj(S, vars{1}, vars{2});
  obj = recursive_setobj(obj, vars(3:end));
  S = setobj(S, vars{1}, obj);
end

