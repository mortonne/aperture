function run_classifier(trainpat,trainreg,testpat,testreg,classifier,params)
%run_classifier(trainpat, trainreg, testpat, testreg)
%
% patterns should be events X channels
% regressors should be vectors the same length as events
%

if ~exist('classifier', 'var')
	classifier = 'bp_netlab';
end
if ~exist('params', 'var')
	params = struct;
end

switch classifier
 case 'bp_netlab'
  params = structDefaults(params, 'nHidden', 10);
  
  trainreg = vec2mat(trainreg);
  testreg = vec2mat(testreg);
  
  sp1 = train_bp_netlab(trainpat', trainreg', params);
  [output, sp2] = test_bp_netlab(testpat', testreg', sp1);
  
 case 'logreg'
  params = structDefaults(params, 'penalty', .5);
  
  trainreg = vec2mat(trainreg);
  testreg = vec2mat(testreg);
  
  sp1 = train_logreg(trainpat', trainreg', params);
  [output, sp2] = test_logreg(testpat', testreg', sp1);
  
end


function mat = vec2mat(vec)

vals = unique(vec);
for i=1:length(vals)
  mat(:,i) = vec==vals(i);
end