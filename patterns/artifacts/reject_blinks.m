function [mask] = reject_blinks(pattern, thresh, varargin)
%REJECT_BLINKS - Reject samples of a pattern based on blink detection.
%
%  Uses a fast and slow running average to detect fast, large, and
%  positive changes in amplitude (i.e. blinks). May also detect upward
%  saccades.
%
%  INPUTS:
%   pattern:  [events X channels X time] matrix.
%
%    thresh:  fast threshold in uV used for marking blinks, i.e. maximum
%             allowable EOG running average for an event to be included.
%             Default: 100
%
%  OUPUTS:
%      mask:  logical array the same size as pattern; true samples mark
%             events with blinks.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   chans        - index of EOG channels search for blinks:
%                   chans(1) - index of a channel above the eye
%                   chans(2) - index of a channel below the eye
%                  Note that these are indices in the pattern matrix,
%                  which may be different from the corresponding channel
%                  numbers. ([8 126])
%   runavg_vals  - a,b,c,d values of running average.
%                  ([.5 .5 .975 .025])
%   reject_full  - if true, entire events will be rejected. If false,
%                  only the samples around the blink (specified by
%                  buffer) will be rejected. (true)
%   buffer       - buffer is ms around the start of each blink to mark
%                  as bad in the form of [-pre_blink post_blink].
%                  ([-150 500])
%   samplerate   - samplerate in Hz; required if specifying a buffer.
%                  ([])
%   debug_plots  - if true, will make plots of individual traces with
%                  blinks marked. (false)
%   debug_images - if true, will plot images of the voltage and the
%                  blink mask. (false)
%   verbose      - if true, more information will be printed. (true)

if ~exist('thresh','var')
  thresh = 100;
end

% options
defaults.chans = [8 126];
defaults.runavg_vals = [.5, .5, .975, .025];
defaults.reject_full = true;
defaults.buffer = [-150 500];
defaults.samplerate = [];
defaults.debug_plots = false;
defaults.debug_images = false;
defaults.verbose = true;
params = propval(varargin, defaults);

% calculate the EOG channel diff and permute to get [events X time]
ev_dat = permute((pattern(:, params.chans(1),:) - ...
                  pattern(:, params.chans(2),:)), [1,3,2]);

%this vector will index trials with blinks
if params.reject_full
  ev_mask = false(size(pattern,1), 1);
else
  ev_mask = false(size(pattern,1), size(pattern,3));
end

% only used for debugging plots
if ~params.reject_full || params.debug_plots || params.debug_images
  if isempty(params.samplerate)
    error('If using a buffer or making plots, must specify a samplerate.')
  end
  step = 1000 / params.samplerate;
  x = [1:size(ev_dat, 2)] * step;
  y = 1:size(ev_dat, 1);
end

%this has been adapted from findBlinks and find_eog_art to work on
%patterns and to be compatible with reject_artifacts
for e = 1:size(ev_dat,1)
  dat = ev_dat(e,:);
  % init the two running averages
  fast = zeros(1,length(dat));
  slow = zeros(1,length(dat));
  
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
  end
  
  % check for thresh
  ind = fast >= thresh;
  
  if ~any(ind)
    continue
  elseif params.reject_full
    ev_mask(e) = 1;
    continue
  end

  if ~isempty(params.buffer)
    % convert buffer values to samples
    pre = ms2samp(params.buffer(1), params.samplerate);
    post = ms2samp(params.buffer(2), params.samplerate);
    
    % find starts of identified blinks
    blink_starts = find([0 diff(ind)] > 0);
    for j=1:length(blink_starts)
      % mark a buffer around the start of this blink
      start = blink_starts(j) + pre;
      if start < 1
        start = 1;
      end
      finish = blink_starts(j) + post;
      if finish > length(ind)
        finish = length(ind);
      end
      ind(start:finish) = true;
    end
  end
  
  % example traces with blinks marked
  if params.debug_plots
    n_plots = 5;
    subplot(n_plots, 1, mod(e-1, n_plots)+1)
    cla
    plot_erp(dat, x, 'mark', ind);
    pause(.75)
    drawnow
  end
  
  ev_mask(e,:) = ind;
end

% voltage image and a mask image
if params.debug_images
  clf
  subplot(1,2,1)
  imagesc(x, y, ev_dat, [-50 50])
  subplot(1,2,2)
  imagesc(x, y, ev_mask)
  drawnow
end

% make a mask the same size as the input pattern (necessary for
% compatibility with reject_artifacts)
if params.reject_full
  mask = repmat(ev_mask, [1, size(pattern, 2), size(pattern, 3)]);
else
  ev_mask = permute(ev_mask, [1 3 2]);
  mask = repmat(ev_mask, [1, size(pattern, 2), 1]);
end

if params.verbose
  fprintf(['Removed %d samples ' ...
           'of %d (%.f%%) whose EOG running average exceeded %d. \n'], ...
          nnz(ev_mask), numel(ev_mask), (nnz(ev_mask) / numel(ev_mask)) * 100, ...
          thresh)
end

