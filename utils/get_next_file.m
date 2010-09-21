function out_file = get_next_file(file)
%GET_NEXT_FILE   Generate a filepath to avoid overwriting existing files.
%
%  out_file = get_next_file(file)

[pathstr, name, ext] = fileparts(file);
out_name = name;
n = 0;
while exist(fullfile(pathstr, [out_name ext]), 'file')
  n = n + 1;
  out_name = sprintf('%s%d', name, n);
end

out_file = fullfile(pathstr, [out_name ext]);

