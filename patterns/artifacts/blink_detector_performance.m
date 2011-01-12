function [d, pHit, pFA, stats] = blink_detector_performance(pat, varargin)
%BLINK_DETECTOR_PERFORMANCE   Calculate performance of a blink detector.
%
%  Determine performance of a blink detector by testing it on various
%  eye movements. If the blink detector marks a blink, that is a hit; if
%  the blink detector marks any other eye movement, that is a false
%  alarm. D-prime is calculated as a measure of how well the blink
%  detector can discriminate between blinks and other eye movements.
%
%  [d, pHit, pFA, stats] = blink_detector_performance(pat, ...)
%
%  INPUTS:
%      pat:  a pattern object containing blink, up, down, left, and
%            right eye movements.
%
%  OUTPUTS:
%        d:  d-prime calculated from the blink detector's hit and false
%            alarm rates.
%
%     pHit:  (N hits) / (N blinks)
%
%      pFA:  (N false alarms) / (N non-blinks)
%
%    stats:  structure with additional statistics.
%
%  PARAMS:
%   These options may be specified using parameter, value pairs or by
%   passing a structure. Defaults are shown in parentheses.
%    blink_thresh - fast threshold in uV used for marking blinks, i.e.
%                   maximum allowable EOG running average for an event
%                   to be included. (100)
%    reject_full  - if true, entire events will be rejected. If false,
%                   only the samples around the blink (specified by
%                   buffer) will be rejected. (true)
%   May also specify other params for reject_blinks.
%
%  See also optimize_blink_detector, remove_eog_glm.

% Copyright 2007-2011 Neal Morton, Sean Polyn, Zachary Cohen, Matthew Mollison.
%
% This file is part of EEG Analysis Toolbox.
%
% EEG Analysis Toolbox is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% EEG Analysis Toolbox is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with EEG Analysis Toolbox.  If not, see <http://www.gnu.org/licenses/>.

% options
defaults.reject_full = true;
defaults.blink_thresh = 100;
params = propval(varargin, defaults, 'strict', false);

% filter to get only relevant trackball events
filter = 'ismember(type, {''blink'',''up'',''down'',''left'',''right''})';
pat = filter_pattern(pat, 'event_filter', filter, 'save_mats', false, ...
                     'verbose', false);
pattern = get_mat(pat);
pat.mat = [];
events = get_dim(pat.dim, 'ev');

% create eye movement type masks
blink_evs = strcmp({events.type}, 'blink');
up_evs = strcmp({events.type}, 'up');
down_evs = strcmp({events.type}, 'down');
left_evs = strcmp({events.type}, 'left');
right_evs = strcmp({events.type}, 'right');

% run blink detection
p = rmfield(params, 'blink_thresh');
blink_mask = reject_blinks(pattern, params.blink_thresh, p);

% get events labeled as blinks
% (first channel and sample will be same as others)
blink_hits = blink_mask(:,1,1)';

% calculate probability of hits and false alarms
pHit = nnz(blink_evs & blink_hits) / nnz(blink_evs);
pFA = nnz(~blink_evs & blink_hits) / nnz(~blink_evs);

% calculate dprime
pHit = norminv_fix(pHit);
pFA = norminv_fix(pFA);
d = dprime(pHit, pFA);

stats = [];
stats.eog_thresh = params.blink_thresh;
stats.dprime = d;
stats.pHit = pHit;
stats.pFA = pFA;

% FAs by event type
stats.pFA_up = nnz(up_evs & blink_hits) / nnz(up_evs);
stats.pFA_down = nnz(down_evs & blink_hits) / nnz(down_evs);
stats.pFA_left = nnz(left_evs & blink_hits) / nnz(left_evs);
stats.pFA_right = nnz(right_evs & blink_hits) / nnz(right_evs);

function y = norminv_fix(x)
  delta = 0.001;
  if x == 1
    y = x - delta;
  elseif x == 0
    y = x + delta;
  else
    y = x;
  end

