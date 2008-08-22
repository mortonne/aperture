function [class,posterior] = corr_class(testpat,trainpat,trainreg)
%
%
%
%
%


these_cats = unique(trainreg);

for i=1:length(these_cats)
  c(i,:) = mean(trainpat(trainreg==these_cats(i),:));  
end

for i=1:size(testpat,1)
  
  out = zeros(1,size(c,1));
  for j=1:size(c,1)
    out(j) = corr(c(j,:)',testpat(i,:)');
  end
  [temp class(i)] = max(out); 
  posterior(i,:) = out;
end

% keyboard

