function pc = init_pc(pcname, file, params)
%stat = init_stat(pcname, file, params)

if ~exist('pcname', 'var')
  pcname = '';
end
if ~exist('file', 'var')
  file = '';
end
if ~exist('params', 'var')
  params = struct();
end

pc = struct('name', pcname, 'file', file, 'params', params);