function [best_thresh, res] = optimize_blink_detector(pat, varargin)
%OPTIMIZE_BLINK_DETECTOR   Use trackball data to optimize a blink detector.
%
%  Optimize blink detector parameters using trackball data. The
%  threshold with the greatest d-prime (ability to distinguish between
%  blinks and eye movements) will be output, along with stats for the
%  other thresholds.
%
%  [best_thresh, res] = optimize_blink_detector(pat, ...)
%
%  INPUTS:
%          pat:  a pattern object containing blink, up, down, left, and
%                right eye movements.
%
%  OUTPUTS:
%  best_thresh:  the optimal threshold for detecting blinks but not
%                eye movements.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   search_thresh - array of threshold values to search over.
%                   (100:10:300)
%   min_hits      - minimum hit rate that the winning detector must
%                   have. (0.8)
%  May also specify params for reject_blinks.
%
%  See also remove_eog_glm.

% options
defaults.search_thresh = 100:10:300;
defaults.min_hits = 0.8;
[params, blink_params] = propval(varargin, defaults);

res = [];

% print the performance header
header = {'Thresh', 'Hits', 'FA (up)', 'FA (down)', 'FA (left)', ...
          'FA (right)', 'D-prime'};
for i=1:length(header)
  fprintf('%-11s', header{i})
end
fprintf('\n')

blink_params.verbose = false;
for i=1:length(params.search_thresh)
  fprintf('%-11d', params.search_thresh(i))
  blink_params.blink_thresh = params.search_thresh(i);

  % run the detector and get performance
  res(i).thresh = params.search_thresh(i);
  [res(i).d, res(i).pHit, res(i).pFA, res(i).stats] = ...
                                 blink_detector_performance(pat, blink_params);

  % print performance
  s = res(i).stats;
  fprintf('%-11.2f%-11.2f%-11.2f%-11.2f%-11.2f%-11.2f\n', ...
          s.pHit, s.pFA_up, s.pFA_down, s.pFA_left, ...
          s.pFA_right, s.dprime)
end

% try the highest d-prime
[y, best_d] = max([res.d]);
if res(best_d).pHit < params.min_hits
  % if hits are less than the minimum for the best d-prime,
  % conditionalize on that and find lowest FA
  good = [res.pHit] >= params.min_hits;
  if any(good)
    min_fa = min([res(good).pFA]);
    best_fa = find([res.pFA] == min_fa);
    best_d = best_fa;
  else
    best_d = find(params.search_thresh == min(params.search_thresh));
  end
end

% this sometimes returns more than one index so choose the first
if length(best_d) > 1
  best_d = best_d(1);
end

best_thresh = params.search_thresh(best_d);


