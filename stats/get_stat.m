function x = get_stat(stat, name, index)
%GET_STAT   Get a variable from a statistics object.
%
%  x = get_stat(stat, name, index)
%
%  INPUTS:
%     stat:  a statistics object.
%
%     name:  name of the variable to load.
%
%    index:  (optional) the index of the variable to load. May be either
%            an index for referencing the variable matrix or a string
%            or cell array of strings giving the name(s) to load (must
%            be a "names" cell array of strings in stat.file)

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

% load the variable
x = getfield(load(stat.file, name), name);

% get the right index
if exist('index', 'var')
  if isnumeric(index) || islogical(index)
    x = x(index,:,:,:);
  elseif ischar(index)
    load(stat.file, 'names')
    match = ismember(names, index);
    if isempty(match)
      error('no variables named ''%s'' in file: %s', index, stat.file)
    end
    x = x(match,:,:,:);
  else
    error('invalid index')
  end
end

