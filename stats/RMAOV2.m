function output = RMAOV2(data, group)
%RMAOV2   Two-way repeated measures ANOVA.
%
%  output = RMAOV2(data, group)
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
infile = fullfile(tempdir, 'temp.txt');
outfile = tempname(tempdir);

% fix regressors to standard format
for i=1:length(group)
  group{i} = make_index(group{i});
end

% write data to a text file
export_R(data, group, infile)
output = run_R('RMAOV2.R', infile);

% clean up
delete(infile)

