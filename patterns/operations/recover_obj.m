function exp = recover_obj(exp, obj_dir, obj_path, obj_type, file_stem)
%RECOVER_OBJ   Load an exp structure object from disk.
%
%  exp = recover_obj(exp, obj_dir, obj_path, obj_type, file_stem)
%
%  INPUTS:
%      exp:  an experiment object.
%
%  obj_dir:  directory containing subject pattern objects. The function
%            will attempt to add "obj" variables from all MAT-files in
%            the directory.
%
% obj_path:  type, name pairs in a cell array, gives the path to
%            the object, leaves off the initial 'subj' subjname
%            pair.  Example: {'pat','this_pat_name','stat'}
%
% obj_type:  e.g., 'stat'
%
% file_stem: string of the target filename, leaving off the subj id
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

% step over each of the subjs and if the file is there, load it.
for i = 1:length(exp.subj)
  filename = fullfile(obj_dir, ...
                      strcat(file_stem, exp.subj(i).id, '.mat'));
  
  % if this filename corresponds to a real file, load it
  if exist(filename, 'file')
    obj = getfield(load(filename, obj_type), obj_type);
    exp = setobj(exp, 'subj', exp.subj(i).id, obj_path{:}, obj);
  else
    fprintf('File does not exist: %s\n', filename)
  end
end


