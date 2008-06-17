function S = recursive_strrep(S, repStr)
%
%RECURSIVE_STRREP   Run strrep on all strings in a structure.
%   S = RECURSIVE_STRREP(S,REPSTR)
%

Fnames = fieldnames(S);
for i=1:length(Fnames)
	for j=1:length(S)
		F = getfield(S(j), Fnames{i});

		% run strrep if applicable
		if isstr(F) | iscell(F)
			for r=1:size(repStr,1)
				try
					F = strrep(F, repStr{r,1}, repStr{r,2});
				catch
					break
				end
			end
		end

		% or call function recursively
		if isstruct(F)
			F = recursive_strrep(F, repStr);
		end

		S(j) = setfield(S(j), Fnames{i}, F);

	end
end
