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

statistic = NaN(1,length(group));

% remove missing data from X and the regressors
good = ~isnan(X);
X = X(good);
for i=1:length(group)
  group{i} = group{i}(good,:);
end

switch test
  case 'pttest'
  % fix all labels to be consecutive integers
  group = fix_regressors(group);
  
  % process the condition labels
  if length(unique(group{1}))~=2
    error('factor must only contain two unique values.')
  end

  % assuming pairs are in the same order, e.g.
  % group{1}: [1 2 1 2 1 2]
  % group{2}: [1 1 2 2 3 3]
  [h,p,ci,stats] = ttest(X(group{1}==1), X(group{1}==2), varargin{:});
  statistic = stats.tstat;
  
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
   p = RMAOV2_mod([X group{1} group{2} group{3}], 0.05, 0);
   
   otherwise
   error('Unknown statistical test: %s.', test)
end

if length(statistic)~=length(p)
  error('length of statistic does not match length of p.')
end

function group = fix_regressors(group)
  % fixes regressors so their labels are one-indexed and consecutive
  temp = group;
  for i=1:length(temp)
    vals = unique(temp{i});
    for j=1:length(vals)
      group{i}(temp{i}==vals(j)) = j;
    end
  end
%endfunction

function export_r(X,group,filename)
  % if the file already exists, delete and start fresh
  if exist(filename,'file')
    unix(['rm ' filename]);
  end

  if ~exist(fileparts(filename),'dir')
    mkdir(fileparts(filename));
  end

  % open a temporary file for writing
  fid = fopen(filename,'w');
  for i=1:length(X)
    fprintf(fid,'%.4f',X(i));
    for j=1:length(group)
      fprintf(fid,'\t%d',group{j}(i));
    end
    fprintf(fid,'\n');
  end
%endfunction
