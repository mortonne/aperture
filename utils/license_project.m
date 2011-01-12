function license_project(project_dir, license_file)
%LICENSE_PROJECT   Write license headers in all code in a project.
%
%  license_project(project_dir, license_file)

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

% find all M-files in this directory
w = what(project_dir);

% write licenses for each
for i = 1:length(w.m)
  write_license(w.m{i});
end

% find directories
d = dir(project_dir);
d = d([d.isdir])
for i = 1:length(d)
  if strcmp(d(i).name(1), '.')
    continue
  else
    % not a hidden directory; call recursively
    license_project(fullfile(project_dir, d(i).name), license_file);
  end
end

