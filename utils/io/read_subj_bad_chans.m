function [numbers, session] = read_subj_bad_chans(file)
%READ_SUBJ_BAD_CHANS   Read a bad channels file for a subject.
%
%  [numbers, session] = read_subj_bad_chans(file)

fid = fopen(file, 'r');

session = [];
numbers = {};
l = fgetl(fid);
while l ~= -1
  c = strsplit(l, ':');
  session = [session str2num(c{1})];

  n_str = deblank(c{2});
  n_sess = cell2num(cellfun(@str2num, strsplit(n_str, ','), ...
                            'UniformOutput', false));
  numbers = [numbers {n_sess}];

  l = fgetl(fid);
end

fclose(fid);

