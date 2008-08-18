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

	otherwise
	error('Error:unknown classifier.')
end


function mat = vec2mat(vec)

	vals = unique(vec);
	for i=1:length(vals)
		mat(:,i) = vec==vals(i);
	end
