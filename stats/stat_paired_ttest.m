function [p, statistic] = stat_paired_ttest(data, group, varargin)
%Run a paired-samples ttest.
%
%  [p, statistic] = stat_paired_ttest(data, group)
%
%  INPUTS:
%     data:  vector of numeric data.
%
%    group:  cell array of factors. Each factor may be numeric or a cell
%            array of strings. The first factor must be subject labels,
%            and the second factor is the independent variable of
%            interest. The sign of the t-statistic is determined as
%            follows:
%             sorted = unique(group{2});
%             label1 = sorted(1);
%             label2 = sorted(2);
%            t is calculated based on label1 - label2.
%
%  NOTES:
%  Currently only runs two-tailed tests.

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

if length(group) ~= 2
  error('must have exactly two factors.')
end

% unpack
v1 = make_index(group{2});
subj = group{1};

% split data
usubj = unique(subj);
n_subj = length(usubj);
data1 = NaN(n_subj, 1);
data2 = NaN(n_subj, 1);
for i = 1:n_subj
  data1(i) = data(strcmp(subj, usubj{i}) & v1 == 1);
  data2(i) = data(strcmp(subj, usubj{i}) & v1 == 2);
end

% run a two-tailed paired ttest
[h, p, ci, stats] = ttest(data1, data2, 0.05, 'both');
statistic = stats.tstat;

