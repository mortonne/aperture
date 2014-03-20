function tf = find_clusters(x, thresh)
%FIND_CLUSTERS   Find clusters in a mask.
%
%  Finds clusters of true elements that pass a length threshold.
%
%  tf = find_clusters(x, thresh)

% find trains
d = diff(x);
new_train_flags = [0 abs(d) > 0];
train_no = 1;
trains = NaN(size(x));
for i = 1:length(x)
  if new_train_flags(i) == 1
    train_no = train_no + 1;
  end
  trains(i) = train_no;
end

% length of each train
utrains = unique(trains);
train_lens = NaN(size(x));
for i = 1:length(utrains)
  train_lens(trains == utrains(i)) = nnz(trains == utrains(i));
end

% apply threshold
tf = train_lens >= thresh & x;

