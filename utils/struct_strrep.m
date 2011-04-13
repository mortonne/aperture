function s = struct_strrep(s, varargin)
%STRUCT_STRREP   Recursively run strrep on all strings in a structure.
%
%  s = struct_strrep(s, varargin)
%
%  INPUTS:
%         s:  structure containing strings to be modified.
%
%  varargin:  any number of string pairs, where the first is the string
%             to replace, and the second is the string to replace it
%             with.
%
%  OUTPUTS:
%         s:  modified structure.
%
%  EXAMPLE:
%   clear s
%   s.string = 'hello world!';
%   s.subfield.string = 'hi!';
%   s = struct_strrep(s, 'hi', 'hi, Dr. Nick', ...
%                     'hello world', 'hi, everybody');

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
if ~exist('s', 'var')
  error('You must input a structure.')
elseif ~isstruct(s)
  error('s must be a structure.')
elseif ~iscellstr(varargin) || mod(length(varargin), 2)
  error('varargin must contain pairs of strings.')
end

fnames = fieldnames(s);
for i = 1:numel(s)
  for j = 1:length(fnames)
    fname = fnames{j};
    
    % get the field for this element of the structure
    f = s(i).(fname);

    % run strrep if applicable
    if isstr(f) || iscellstr(f)
      for r = 1:2:length(varargin)
        to_replace = varargin{r};
        replacement = varargin{r+1};
        f = strrep(f, to_replace, replacement);
      end
    end

    % or call function recursively
    if isstruct(f)
      f = struct_strrep(f, varargin{:});
    end

    % we're done with this element; set it back in the structure
    s(i).(fname) = f;
  end
end

