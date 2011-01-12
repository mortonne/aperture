function license_project(project_dir, license_file)
%LICENSE_PROJECT   Write license headers in all code in a project.
%
%  license_project(project_dir, license_file)

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

