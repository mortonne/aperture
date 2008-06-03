function [trainpat, testpat] = prep_patclass(trainpat, testpat)
%run_classifier(trainpat, testpat)
%
% patterns should be events X channels
%

% remove channels that were thrown out for either train or test
cboth = intersect(find(sum(~isnan(trainpat))), find(sum(~isnan(testpat))));
trainpat = trainpat(:,cboth);
testpat = testpat(:,cboth);

% set all other NaN's to the mean for that channel
for c=1:size(trainpat,2)
  badevents = isnan(trainpat(:,c));
  trainpat(badevents,c) = nanmean(trainpat(:,c));
  
  badevents = isnan(testpat(:,c));
  testpat(badevents,c) = nanmean(testpat(:,c));	  
end
