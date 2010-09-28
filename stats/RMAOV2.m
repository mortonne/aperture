function res = RMAOV2(data, group, varargin)
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
c = textscan(fid, '%n%n');
fclose(fid);

res.statistic = c{1};
res.p = c{2};

% clean up
delete(infile)
delete(outfile)

