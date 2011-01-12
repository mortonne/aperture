function [p, statistic] = run_sig_test(X,group,test,varargin)
%RUN_SIG_TEST   Run a test of significance using standard input/output.
%
%  [p, statistic] = run_sig_test(X, group, test, varargin)
%
%  INPUTS:
%          X:  vector of data.
%
%      group:  cell array of grouping variables. Each cell should
%              contain labels for one factor; labels can be integers
%              or strings.
%
%       test:  string indicating which test to run. Choices are:
%               'pttest'
%               'anovan'
%               'RMAOV1'
%               'RMAOV2'
%
%  OUTPUTS:
%          p:  p-value of the test.
%
%  statistic:  statistic corresponding to the p-value (e.g. t-
%              or F-statistic)

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

% input checks
if ~exist('X','var')
  error('You must pass a data vector.')
  elseif ~isnumeric(X)
  error('X must be a numeric array.')
  elseif ~exist('group','var')
  error('You must pass a cell array of grouping variables.')
end
if ~exist('test','var')
  test = 'anovan';
end

% initialize the outputs
p = NaN(1,length(group));
statistic = NaN(1,length(group));

% find missing observations
n_obs = length(X);
good = ~isnan(X);

if ~any(good)
  fprintf('Data is all NaNs; cannot test significance.\n')
  return
end

% remove bad observations
if ~strcmp(test,'pttest')
  % if this is a paired test, we'll need to make sure both
  % observations in a pair are removed.
  % otherwise, we can just remove the bad observations:
  X = X(good);
  for i=1:length(group)
    group{i} = group{i}(good,:);
  end
end

switch test
 case 'pttest'
  if sum(good)<n_obs
    % we have some bad samples, and we will have to throw
    % out pair(s).
    bad_obs = find(~good);
    
    % logical indicating observations to remove
    rm = false(size(X));
    for i=1:length(bad_obs)
      % get the pair corresponding to this bad sample
      % assuming group{2} contains strings!
      pair = strcmp(group{2}, group{2}{bad_obs(i)});
      rm(pair) = true;
    end
    
    % remove the bad pairs
    X(rm) = [];
    group{1}(rm) = [];
    group{2}(rm) = [];
  end
  
  % fix all labels to be consecutive integers
  [group,good_labels] = fix_regressors(group);
  
  % remove points that had invalid labels
  X = X(good_labels);
  
  % process the condition labels
  n_labels = length(unique(group{1}));
  if n_labels>2
    error('factor cannot contain more than two unique values.')
  end

  % assuming pairs are in the same order, e.g.
  % group{1}: [1 2 1 2 1 2]
  % group{2}: [1 1 2 2 3 3]
  
  if n_labels==2
    % take the difference between the two conditions for each pair
    X = X(group{1}==2) - X(group{1}==1);
    [h,p,ci,stats] = ttest(X, 0, 0.05, 'both');
    
    elseif n_labels==1
    % difference has already been taken
    [h,p,ci,stats] = ttest(X, 0, 0.05, 'both');
  end
  
  % add sign to the p-values
  p = p*sign(mean(X));
  statistic = stats.tstat;

 case 'anova1'

  [p,anovatab] = anova1(X,group{1},'off');
  statistic = anovatab{2,5};
  
 case 'anovan'
   [p,t,stats,terms] = anovan(X,group,'display','off',varargin{:});
   
   % get the F-statistic
   statistic = t{2:end-2, 6};
   
  case 'RMAOV1'
   group = fix_regressors(group);
   %filename = varargin{1};
   
   % write an output file
   %export_r(X,group,filename);
   %keyboard
   % delete existing input file
   % run r code
   % wait for input file to be created
   % read input file
   
   p = RMAOV1_mod([X group{1} group{2}], 0.05, 0);
   
  case 'RMAOV2'
   group = fix_regressors(group);
   Y = [X group{1} group{2} group{3}];
   
   p = RMAOV2_mod(Y, 0.05, 0);
   
   % remove the subject term
   p = p(1:3);
   
   otherwise
   error('Unknown statistical test: %s.', test)
end

if length(statistic)~=length(p)
  error('length of statistic does not match length of p.')
end
