function pat = upgrade_pattern(pat)
%UPGRADE_PATTERN   Upgrade a pattern to use the new dim format.
%
%  pat = upgrade_pattern(pat)

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

