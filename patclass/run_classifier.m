function [class,err,posterior] = run_classifier(trainpat,trainreg,testpat,testreg,classifier,params)
%RUN_CLASSIFIER   Train and test a classifier using standard data formats.
% 
%run_classifier(trainpat, trainreg, testpat, testreg)
%
% patterns should be observations X variables.
% regressors should be vectors the same length as observations.
%

if ~exist('classifier', 'var')
	classifier = 'bp_netlab';
end
if ~exist('params', 'var')
	params = struct;
end

class = [];
err = [];
posterior = [];

switch classifier
	case 'bp_netlab'
	params = structDefaults(params, 'nHidden', 10);

	trainreg = vec2mat(trainreg);
	testreg = vec2mat(testreg);

	sp1 = train_bp_netlab(trainpat', trainreg', params);
	[output, sp2] = test_bp_netlab(testpat', testreg', sp1);

	case 'logreg'
	params = structDefaults(params, 'penalty', .5);

	% adapt the inputs
	trainreg = vec2mat(trainreg);
	testreg = vec2mat(testreg);

	% run the classifier
	sp1 = train_logreg(trainpat', trainreg', params);
	[posterior,sp2] = test_logreg(testpat', testreg', sp1);

	% standardize the outputs
	err = sp2.logreg.trainError;
	[m,i] = max(posterior);
	class = i';
	posterior = posterior';

	case 'classify'
	params = structDefaults(params, 'type', 'linear');

	[class,err,posterior] = classify(testpat, trainpat, trainreg, params.type);

  case 'correlation'
	[class,posterior] = corr_class(testpat,trainpat,trainreg); 
  
	case 'svm'
	% LIBSVM VERSION
	% standardize input
	trainreg = grp2idx(trainreg);
	testreg = grp2idx(testreg);
	keyboard
	% train
	model = svmtrain(trainreg,trainpat);
	
	% test; not sure what range of posterior is. Should we normalize so
	% it's between 0 and 1?
	[class,temp,posterior] = svmpredict(testreg,testpat,model);
	err = 1-(temp(1)/100);
	
	%{
	% MATLAB VERSION
	% function can't handle more than two groups, so iterate over groups,
	% train on group members versus everything else	
	uniq_reg_vals = unique(trainreg);
	for i=1:length(uniq_reg_vals)
	  % separate into two groups
	  this_trainreg = ismember(trainreg,uniq_reg_vals(i));
	  
	  % train the classifier
	  svm_struct = svmtrain(trainpat,this_trainreg);
	  
	  % test
	  groups = svmclassify(svm_struct,testpat);keyboard
  end
  %}
	
	otherwise
	error('Error:unknown classifier.')
end

function mat = vec2mat(vec)

	vals = unique(vec);
	for i=1:length(vals)
		mat(:,i) = vec==vals(i);
	end
%endfunction
