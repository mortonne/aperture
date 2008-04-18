function pc = init_pc(pcname, file, pat, params)
%stat = init_stat(pcname, file, pat, params)

if ~exist('pcname', 'var')
  pcname = '';
end
if ~exist('file', 'var')
  file = '';
end
if ~exist('pat', 'var')
  pat = struct();
end
if ~exist('params', 'var')
  params = struct();
end

pc = struct('name', pcname, 'file', file, 'pat', pat, 'params', params);