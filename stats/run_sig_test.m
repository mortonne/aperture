function p = run_sig_test(X,group,test,varargin)
%RUN_SIG_TEST   Run a test of significance using standard input/output.
%   P = RUN_SIG_TEST(TEST,X,GROUP,VARARGIN) runs significance test
%   indicated by the string TEST on data in X. Regressors are specified
%   in the cell array GROUP. Additional inputs to the significance test
%   function are passed in as VARARGIN.
%

% remove missing data from X and the regressors
good = ~isnan(X);
X = X(good);
for i=1:length(group)
  group{i} = group{i}(good,:);
end

switch test
  case 'anovan'
   p = anovan(X,group,'display','off',varargin{:});
  
  case 'RMAOV1'
   group = fix_regressors(group);
   filename = varargin{1};
   export_r(X,group,filename);
   keyboard
   % run r code
   % return
   
   %p = RMAOV1_mod([X group{1} group{2}], 0.05, 0);
   
  case 'RMAOV2'
   group = fix_regressors(group);
   p = RMAOV2_mod([X group{1} group{2} group{3}], 0.05, 0);
   
   otherwise
   error('Unknown statistical test: %s.', test)
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
  