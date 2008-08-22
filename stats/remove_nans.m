function [mat,goodind] = remove_nans(mat)
%REMOVE_NANS
%   [MAT,GOODIND] = REMOVE_NANS(MAT)
% matrix must be observations X vars
% returns changed matrix and indices of variables that had at least one data point
%

%goodind = find(sum(~isnan(mat)));

% remove vars that are all nans
%mat = mat(:,goodind);

% replace remaining nans with the mean for that var across observations
varmeans = nanmean(mat);

for i=1:size(mat,2)
  badobs = isnan(mat(:,i));
  mat(badobs,i) = varmeans(i);
end
