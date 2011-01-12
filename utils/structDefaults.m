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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

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

