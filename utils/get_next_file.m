function out_file = get_next_file(file)
%GET_NEXT_FILE   Generate a filepath to avoid overwriting existing files.
%
%  out_file = get_next_file(file)

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

[pathstr, name, ext] = fileparts(file);
out_name = name;
n = 0;
while exist(fullfile(pathstr, [out_name ext]), 'file')
  n = n + 1;
  out_name = sprintf('%s%d', name, n);
end

out_file = fullfile(pathstr, [out_name ext]);

