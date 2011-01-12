function pat = upgrade_pattern(pat)
%UPGRADE_PATTERN   Upgrade a pattern to use the new dim format.
%
%  pat = upgrade_pattern(pat)

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

% backup the pat object before we change it
save(pat.file, 'pat', '-v7.3', '-append');

dim_info = pat.dim;

for i = 2:4
  [dim_name, t, t, dim_long_name] = read_dim_input(i);
  
  % initialize the dim in the new format
  dim = get_dim(dim_info, dim_name);
  dim_info.(dim_name) = init_dim(dim_name);

  % set the file name
  dim_dir = get_pat_dir(pat, dim_long_name);
  dim_file = fullfile(dim_dir, ...
                      objfilename(dim_long_name, pat.name, pat.source));
  dim_info.(dim_name).file = dim_file;

  % save
  dim_info = set_dim(dim_info, dim_name, dim, 'hd');
end

pat.dim = dim_info;

