function [p, F, res] = RMAOV2(data, group, varargin)
%RMAOV2   Two-way repeated measures ANOVA.
%
%  res = RMAOV2(data, group, ...)
%
%  INPUTS:
%     data:  vector of numeric data.
%
%    group:  cell array of factors; must be of the form:
%             {subject IV1 IV2}
%            that is, group{1} should contain subject identifiers,
%            group{2} the first independent variable, and group{3} the
%            second independent variable. Each factor may be numeric or
%            a cell array of strings.

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

if length(group) ~= 3
  error('must have three factors.')
end

% get temporary files to write to
tempdir = '~/.Rtemp';
infile = fullfile(tempdir, 'in.txt');
outfile = fullfile(tempdir, 'out.txt');

% fix regressors to standard format
for i=1:length(group)
  group{i} = make_index(group{i});
end

% write data to a text file
export_R(data, group, infile)

% run the ANOVA in R
res.output = run_R('RMAOV2.R', infile, outfile);

% read the results
fid = fopen(outfile, 'r');
if fid == -1
  warning('no output from R.')
  disp(res.output)
  F = NaN;
  p = NaN;
  delete(infile)
  return
end

c = textscan(fid, '%n%n');
fclose(fid);

F = c{1};
p = c{2};

% clean up
delete(infile)
delete(outfile)

