function S = recursive_rmfield(S, query, vars)
%S = recursive_rmfield(S, vars)

if length(vars)==2
	% we've reached the object to delete
	[obj2rm, ind] = getobj(S, vars{1}, vars{2});

	if isempty(obj2rm)
		fprintf('WARNING: no object "%s" found in field "%s"\n', vars{2}, vars{1});
		return
	end

	%{
	if isfield(obj2rm, 'file')
		files = obj2rm.file;
		if ~iscell(files)
			files = {files};
		end
	else
		keyboard
		% no files attached to this object
		files = {};
	end

	cont = 1;
	for f=1:length(files)
		% check if this file still exists
		if ~exist(files{f}, 'file')
			continue
		end

		% make sure these files are ok to delete
		if query
			promptStr = sprintf('Deleting %s. Continue? >> ', files{f});
			in = input(promptStr, 's');
			if strcmpi(in, 'n') | strcmpi(in, 'no')
				break;
			elseif strcmpi(in, 'n to all') | strcmpi(in, 'no to all')
				cont = 0;
				break;
			elseif strcmpi(in, 'y to all') | strcmpi(in, 'yes to all')
				query = 0;
			end	
		end

		if ~cont
			break
		end

		% it's ok; remove this file
		if exist([files{f} '.lock'], 'file')
			system(['rm -f' files{f} '.lock']);
		end
		system(['rm ' files{f}]);
	end

	if query
		% make sure it's ok to remove the object
		promptStr = sprintf('Removing object "%s" from field "%s". Continue? >> ', vars{2}, vars{1});
		in = input(promptStr, 's');
	end
	%}

	% remove the object
	S.(vars{1})(ind) = [];

elseif length(vars)>2
	% keep going deeper
	obj = getobj(S, vars{1}, vars{2});
	obj = recursive_rmfield(obj, query, vars(3:end));
	S = setobj(S, vars{1}, obj);
end
