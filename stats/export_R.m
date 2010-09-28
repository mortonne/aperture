function export_R(data, group, outfile)
%EXPORT_R   Export data to be read by R.
%
%  export_R(data, group, outfile)
%
%  INPUTS:
%     data:  vector of a dependent measure.
%
%    group:  factor array or cell array of multiple factors. Each cell
%            must contain a vector the same length as data. Vector(s)
%            must be numeric.
%
%  outfile:  path to a file to write the data to. Existing data in
%            outfile will be overwritten.

if ~isvector(data)
  error('data must be a vector')
elseif ~isnumeric(data)
  error('data must be numeric')
end
if ~iscell(group)
  group = {group};
end

n_obs = length(data);
if ~all(n_obs == cellfun(@length, group))
  error('Each factor must be the same length as data')
end
n_factors = length(group);

% make the parent directory if needed
parent = fileparts(outfile);
if ~exist(parent, 'dir')
  mkdir(parent)
end

% open file for writing, overwriting existing contents
fid = fopen(outfile, 'w');
for i=1:n_obs
  fprintf(fid, '%.4f', data(i));
  for j=1:n_factors
    fprintf(fid, '\t%.4f', group{j}(i));
  end
  fprintf(fid, '\n');
end
fclose(fid);

