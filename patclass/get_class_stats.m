function [acts, targs] = get_class_stats(res)
%GET_CLASS_STATS   Get classifier statistics in matrix form.
%
%  Return matrices of classifier statistics. Iterations of a
%  cross-validation scheme are combined to give classifier performance
%  for each tested event.
%
%  [acts, targs] = get_class_stats(res)
%
%  INPUTS:
%      res:  vector structure of length iterations. res must have 'acts'
%            and 'targs' fields.
%
%  OUTPUTS:
%     acts:  [category X events] matrix of
%            values of the output units of the classifier.
%
%    targs:  matrix of values of target category values.

% get dimension sizes
n_iter = length(res);
n_events = length(res(1).train_idx);
n_class = size(res(1).acts, 1);

acts = NaN(n_class, n_events);
targs = NaN(n_class, n_events);
for i = 1:n_iter
  % get acts and targs for the test events
  iter_res = res(i);
  acts(:,iter_res.test_idx) = iter_res.acts;
  targs(:,iter_res.test_idx) = iter_res.targs;
end

% [n_iter, n_chans, n_time, n_freq] = size(res.iterations);
% n_events = length(res.iterations(1).train_idx);
% n_class = size(res.iterations(1).acts, 1);

% acts = NaN(n_class, n_events, n_chans, n_time, n_freq);
% targs = NaN(n_class, n_events, n_chans, n_time, n_freq);
% for i = 1:n_iter
%   for j = 1:n_chans
%     for k = 1:n_time
%       for l = 1:n_freq
%         iter_res = res.iterations(i,j,k,l);
%         acts(:,iter_res.test_idx,j,k,l) = iter_res.acts;
%         targs(:,iter_res.test_idx,j,k,l) = iter_res.targs;
%       end
%     end
%   end
% end

