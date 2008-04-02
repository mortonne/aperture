function exp = rmobj(exp, query, varargin)

load(exp.file);

% make a backup of exp with a timestamp
bk_dir = fullfile(exp.resDir, 'exp_bk');
if ~exist(bk_dir)
  mkdir(bk_dir);
end
bk_file = fullfile(bk_dir, ['exp_' datestr(now) '.mat']);
save(bk_file, 'exp');

% delete the object and any files attached to it, save
exp = recursive_rmfield(exp, query, varargin);
save(exp.file, 'exp');