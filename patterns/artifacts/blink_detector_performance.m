function [d, pHit, pFA, stats] = blink_detector_performance(pat, params)


pattern = get_mat(pat);
events = getfield(load(pat.dim.ev.file),'events');

%create ev masks
blink_evs = strcmp({events.type},'blink');
up_evs = strcmp({events.type},'up');
down_evs = strcmp({events.type},'down');
left_evs = strcmp({events.type},'left');
right_evs = strcmp({events.type},'right');
open_evs = strcmp({events.type},'open');
close_evs = strcmp({events.type},'close');


blink_mask = reject_blinks(pattern, params.blink_thresh, 'verbose', params.verbose, ...
              'chans', params.veog_chans, 'reject_full', true);

%what events are labeled as blinks
blink_hits = blink_mask(:,1,1)';

%how many trials are there
trials = length(events);

%how many of each event are there
blinks = sum(blink_evs);
ups = sum(up_evs);
downs = sum(down_evs);
lefts = sum(left_evs);
rights = sum(right_evs);
opens = sum(open_evs);
closes = sum(close_evs);

%important statistics about detector performance
hits = sum(blink_evs & blink_hits);
misses = sum(blink_evs) - hits;
false_alarms = sum(~blink_evs & blink_hits);
%calculate probability of hits and false alarms
pHit = hits/blinks;
pFA = false_alarms/(trials-blinks);
%calculate dprime
d = dprime(pHit,pFA);


%secondary statistics about other events
up_blinks = sum(up_evs & blink_hits);
down_blinks = sum(down_evs & blink_hits);
left_blinks = sum(left_evs & blink_hits);
right_blinks = sum(right_evs & blink_hits);
open_blinks = sum(open_evs & blink_hits);
close_blinks = sum(close_evs & blink_hits);

pFA_up = up_blinks/ups;
pFA_down = down_blinks/downs;
pFA_left = left_blinks/lefts;
pFA_right = right_blinks/rights;
pFA_open = open_blinks/opens;
pFA_close = close_blinks/closes;

%dHits of 1 give dprimes of infinity, so we must NaN them out
if d>10
  d = NaN;
end

stats = [];
stats.eog_thresh = params.blink_thresh;
stats.dprime = d;
stats.pHit = pHit;
stats.pFA = pFA;
stats.pFA_up = pFA_up;
stats.pFA_down = pFA_down;
stats.pFA_left = pFA_left;
stats.pFA_right = pFA_right;


