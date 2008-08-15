function propval = struct2propval(s)
%STRUCT2PROPVAL   Convert a structure into a cell array of property-value pairs.
%   PROPVAL = STRUCT2PROPVAL(S)
%

fnames = fieldnames(s);
vals = struct2cell(s);
for i=1:length(fnames)
	propval{2*i-1} = fnames{i};
	propval{2*i} = vals{i};
end
