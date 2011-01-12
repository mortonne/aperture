function exp = recover_pat(exp, pat_dir)
%RECOVER_PAT   Load a pattern object from disk.
%
%  exp = recover_pat(exp, pat_dir)
%
%  INPUTS:
%      exp:  an experiment object.
%
%  pat_dir:  directory containing subject pattern objects. The function
%            will attempt to add "obj" variables from all MAT-files in
%            the directory.
%
%  OUTPUTS:
%      exp:  experiment object with the pattern objects added to the
%            appropriate subjects.

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

search_dir = fullfile(pat_dir, '*.mat');
d = dir(search_dir);

for i = 1:length(d)
  filename = fullfile(pat_dir, d(i).name);
  pat = getfield(load(filename, 'obj'), 'obj');
  exp = setobj(exp, 'subj', pat.source, 'pat', pat);
end

