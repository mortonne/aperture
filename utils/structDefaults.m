function s = structDefaults(s, varargin)
%
%STRUCTDEFAULTS Set default values for a structure.
%   STRUCT = STRUCTDEFAULTS(STRUCT,
%   'field1',VALUES1,'field2',VALUES2,...) checks to see if each
%   field already exists, and if not, replaces it with the
%   specified value.  The changed structure is returned.

if length(varargin)>0
	for i=1:2:length(varargin)
		if isempty(s)
			s = struct;
		end
		if ~isfield(s, varargin{i})
			s = setfield(s, varargin{i}, varargin{i+1});
		end
	end
end
