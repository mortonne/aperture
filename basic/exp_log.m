function exp_log(exp, backup_dir)
%EXP_LOG   Print a log of changes to an experiment object.
%
%  exp_log(exp, backup_dir)

% input checks
if ~exist('backup_dir', 'var')
  backup_dir = fullfile(exp.resDir, 'exp_bak');
end

% get a sorted list of all backup files
[files, datenums] = get_backup_files(exp.resDir);

% since there's no fast way to tell if there is a log for any given
% file, just temporarily turn off the warning
warn = warning('query', 'MATLAB:load:variableNotFound');
warning('off', warn.identifier);

for i=length(files):-1:1
  log = '';
  load(files{i}, 'log')

  % print this entry
  fprintf('%s\n', repmat('-', 1, 72));
  fprintf('%d | %s %s\n', i, ...
          datestr(datenums(i), 'yyyy-mm-dd HH:MM:SS'), ...
          datestr(datenums(i), '(dddd, dd mmm yy)'))
  if ~isempty(log)
    fprintf('\n')
    fprintf('%s\n', log)
  end
  fprintf('\n')
end

% set the warning back to where it was
warning(warn.state, warn.identifier);
