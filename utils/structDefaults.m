function s = structDefaults(s, varargin)
%STRUCTDEFAULTS   Set default values for a structure.
%
%  s = structDefaults(s, ...)
%
%  INPUTS:
%         s:  a structure.
%
%  varargin:  fieldname, value pairs for specifying default values for
%             fields of the structure.  If any of the fieldnames listed
%             are not defined in s, they are set to the corresponding
%             default value.
%
%  OUTPUTS:
%         s:  modified structure, with default values set.

% input checks
if ~isempty(s) && ~isstruct(s)
  error('structDefaults: First input must be a structure.')
end

if length(varargin) > 0
  for i=1:2:length(varargin)
    if isempty(s)
      s = struct;
    end
    if ~isfield(s, varargin{i})
      s.(varargin{i}) = varargin{i+1};
    end
  end
end

