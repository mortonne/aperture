function S = recursive_rmfield(S, vars)
%
%RECURSIVE_RMFIELD   Remove a field from a nested structure.
%   S = RECURSIVE_RMFIELD(S,VARS)
%

if length(vars)==2
	% we've reached the object to delete
	[obj2rm, ind] = getobj(S, vars{1}, vars{2});

	if isempty(obj2rm)
		fprintf('WARNING: no object "%s" found in field "%s"\n', vars{2}, vars{1});
		return
	end

	% remove the object
	S.(vars{1})(ind) = [];

elseif length(vars)>2
	% keep going deeper
	obj = getobj(S, vars{1}, vars{2});
	obj = recursive_rmfield(obj, query, vars(3:end));
	S = setobj(S, vars{1}, obj);
end
