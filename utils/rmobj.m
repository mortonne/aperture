function s = rmobj(s, vars)
%RMOBJ   Remove an object from an object hierarchy.
%
%  s = rmobj(s, vars)
%
%  INPUTS:
%        s:  structure containing an object that is to be removed.
%
%     vars:  cell array of object type, object name pairs that climbs
%            the hierarchy of s. The last pair indicates the object
%            to be removed.
%
%  OUTPUTS:
%        s:  the modified structure, with the specified object deleted.

if mod(length(vars),2)~=0
  error('The length of vars must be a multiple of 2.')
  
elseif length(vars)==2
  try
	  % we've reached the object to delete
	  [obj2rm, ind] = getobj(s, vars{1}, vars{2});
	catch
	  % couldn't find it
		fprintf('WARNING: no object "%s" found in field "%s"\n', vars{2}, vars{1});
		return
	end

	% remove the object
	s.(vars{1})(ind) = [];

elseif length(vars)>2
	% get the next object
	obj = getobj(s, vars{1}, vars{2});
	
	% call rmobj with this new object
	obj = rmobj(obj, vars(3:end));
	
	% when we've finished climbing, unwind using setobj
	s = setobj(s, vars{1}, obj);
end
