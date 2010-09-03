function [mask] = reject_blinks(pattern, thresh, varargin)
%reject_blinks - Reject samples of a pattern based on blink detection.
%
% Uses a fast and slow running average to detect fast and large
% changes in amplitude (blinks and eye movements).
%
%  INPUTS:
%   pattern:  [events X channels X time] matrix.
%
%    thresh:  fast threshold in mV used for marking blinks,
%             i.e. maximum allowable EOG absolute value for an
%             event to be included.  Default: 100
%
%  OUPUTS:
%      mask:  logical array the same size as pattern; true samples mark
%             events with blinks.
%
%  PARAMS:
%   verbose - if true, more information will be printed. (true)
%   chans   - eog channels to take difference {[8 126] or [1 32]}  
%   runavg_vals - a,b,c,d values of running average  
%             {[.5 .5 .975 .025]}
%   reject_full - if true, the entire event will be rejected, if
%                false just the bad samples will be rejected.
%   buffer    - if true, blinks samples will be marked 500ms before
%             the first blink detection and 1000ms after


if ~exist('thresh','var')
  thresh = 100;
end

% options
defaults.verbose = true;
defaults.chans = [8 126];
defaults.runavg_vals = [.5, .5, .975, .025];
defaults.reject_full = true;
defaults.buffer = false;
params = propval(varargin, defaults);



%to get the EOG channel diff we subtract one from the other
%we then permute the pattern to make it [events X time]
ev_dat = permute((pattern(:,params.chans(1),:)-pattern(:, ...
                                                  params.chans(2),:)),[1,3,2]);

%this vector will index trials with blinks
if params.reject_full
  ev_mask = zeros(size(pattern,1),1);
else
  ev_mask = zeros(size(pattern,1),size(pattern,3));
end

%this has been adapted from findBlinks and find_eog_art to work on
%patterns and to be compatible with reject_artifacts
for e = 1:size(ev_dat,1)
  dat = ev_dat(e,:);
  % init the two running averages
  fast = zeros(1,length(dat));
  slow = zeros(1,length(dat));
  %ind = logical(zeros(1,length(dat)));
  
  % params
  a = params.runavg_vals(1);
  b = params.runavg_vals(2);
  c = params.runavg_vals(3);
  d = params.runavg_vals(4);
  
  fast_start = 0;
  slow_start = mean(dat(1:10));
  
  for i = 1:length(dat)
    % update the running averages
    % slow subtraction below accounts for baseline
    if i > 1
      fast(i) = a*fast(i-1) + b*(dat(i)-slow(i-1));
      slow(i) = c*slow(i-1) + d*dat(i);
    else
      fast(i) = a*fast_start + b*(dat(i)-slow_start);
      slow(i) = c*slow_start + d*dat(i);    
    end
    
    % check for thresh
    %ind(i) = abs(fast(i))>=thresh;
    
  end
  
  % check for thresh
  ind = logical(abs(fast)>=thresh);
  
  if params.buffer
    if any(ind)
      blink_start = find(ind,1);
      back_step = 50;
      front_step = 150;
      if blink_start-back_step<=0
        back_step = back_step + (blink_start-back_step)-1;
      end
      if blink_start+front_step>length(ind)
        front_step = front_step - ((blink_start+front_step)- ...
                                   length(ind));
      end
      ind(blink_start-back_step:blink_start+front_step) = true;
    end
  end
  
  
  if params.reject_full
    ev_mask(e) = any(ind);
  else
    %store events with blink samples labeled
    ev_mask(e,:) = ind;
  end
end

%in order for this to be compatible with reject_artifacts we
%take the ev_mask that has events samples with blinks labeled and
%expand it to be the size of the original pattern

if params.reject_full
  mask = repmat(ev_mask, [1,size(pattern,2),size(pattern,3)]);
else
  ev_mask = permute(ev_mask, [1 3 2]);
  mask = repmat(ev_mask, [1,size(pattern,2),1]);
end

if params.verbose
  fprintf(['Removed %d events ' ...
           'of %d (%.f%%) whose eog abs. val. exceeded %d. \n'], ...
          sum(ev_mask), numel(ev_mask), (sum(ev_mask) / numel(ev_mask)) * 100, ...
          thresh)
end

