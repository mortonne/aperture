function stat = init_stat(statname, file, params)
%stat = init_stat(statname, file, params)

if ~exist('statname', 'var')
  statname = '';
end
if ~exist('file', 'var')
  file = '';
end
if ~exist('params', 'var')
  params = struct();
end

stat = struct('name', statname, 'file', file, 'params', params);