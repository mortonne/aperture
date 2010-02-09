function [files, datenums] = get_backup_files(res_dir, backup_dir)
%GET_BACKUP_FILES   Get a list of backup experiment object files.
%
%  [files, datenums] = get_backup_files(res_dir, backup_dir)

% input checks
if ~exist('backup_dir', 'var')
  backup_dir = 'exp_bak';
end

% find all backup files
d = dir(fullfile(res_dir, backup_dir, 'exp*'));
files = {d.name};

% get date numbers for sorting
datenums = NaN(1, length(files));
for i=1:length(files)
  [p, name] = fileparts(files{i});
  str = name(5:end);
  datenums(i) = datenum(str, 'mm-dd-yy_HHMM');
  files{i} = fullfile(res_dir, backup_dir, files{i});
end

% sort by date
[datenums, i] = sort(datenums);
files = files(i);
