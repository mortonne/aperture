function add_dep(dep_dir)
%ADD_DEP   Add dependency files used by Aperture to the external directory.
%
%  add_dep(dep_dir)
%
%  INPUTS:
%  dep_dir:  path to main directory of a dependency package.

import matlab.codetools.*

restoredefaultpath
addpath(genpath(dep_dir));

% find all m-files in the aperture project
aperture_dir = fileparts(fileparts(mfilename('fullpath')));
[w, s] = unix(sprintf('find %s -name "*.m"', aperture_dir));
files = regexp(strtrim(s), '\n', 'split');

% find all dependencies of the project that are in the dep_dir
[flist, plist] = requiredFilesAndProducts(files);

% add a directory for this package
[parent, name] = fileparts(dep_dir);
ext_dir = fullfile(aperture_dir, 'external', name);
if ~exist(ext_dir, 'dir')
  mkdir(ext_dir)
end

for i = 1:length(flist)
  % exclude anything in the aperture project directory
  if ~isempty(strfind(flist{i}, 'aperture'))
    continue
  end

  % use just the last part of each directory
  [parent, filename, ext] = fileparts(flist{i});
  [parent, dirname] = fileparts(parent);
  sub_dir = fullfile(ext_dir, dirname);
  if ~exist(sub_dir, 'dir')
    mkdir(sub_dir)
  end

  % copy the needed file
  dest_file = fullfile(sub_dir, [filename ext]);
  copyfile(flist{i}, dest_file);
end

