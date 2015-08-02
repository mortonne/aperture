function [numbers, labels] = read_chan_labels(chan_file)
%READ_CHAN_LABELS   Read channel labels from a standard text file.
%
%  [numbers, labels] = read_chan_labels(chan_file)

fid = fopen(chan_file, 'r');
c = textscan(fid, '%d%s');
numbers = c{1};
labels = c{2};

