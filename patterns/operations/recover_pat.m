function exp = recover_pat(exp, directory)

search_directory = fullfile(directory, '*.mat');
d = dir(search_directory);

for i = 1:length(d)
  filename = fullfile(directory, d(i).name);
  pat = getfield(load(filename),'obj');
  exp = setobj(exp, 'subj', pat.source, 'pat', pat);
end
