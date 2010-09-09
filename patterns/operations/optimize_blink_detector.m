function [best_thresh blink_thresh] = optimize_blink_detector(pat, params)

params.verbose = true;
params.reject_full = true;

blink_thresh = [];

for i = 1:600
  params.blink_thresh = i;
  [blink_thresh(i).d, blink_thresh(i).pHit, blink_thresh(i).pFA, stats] = ...
      blink_detector_performance(pat,params);
end

best_d = find([blink_thresh.d]==max([blink_thresh.d]));

%this sometimes returns more than one index so choose the first
if length(best_d) > 1
  best_d = best_d(1)
end

best_thresh = best_d;


