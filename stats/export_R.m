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

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

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

