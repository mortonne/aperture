function blink_freq = blink_stats(events, window_start, window_end)
%BLINK_STATS   Calculate statistics on blinking during an experiment.
%
%  blink_freq = blink_stats(events, window_start, window_end)
%
%  INPUTS:
%        events:  an events structure. Must be aligned and have an
%                 artifactMS field (created by addArtifacts).
%
%  window_start:  time in ms relative to the onset of each event to
%                 count artifacts. Value must be positive.
%                 Alternatively, may be a string name of a field in
%                 events containing numeric values.
%
%    window_end:  time in ms or string name of a field of events.
%
%  OUTPUTS:
%    blink_freq:  fraction of events containing artifacts.

% input checks
if ~isfield(events, 'artifactMS')
  error('events must have an artifactMS field. Run addArtifacts.')
end

art = [events.artifactMS];
if ischar(window_start)
  window_start = [events.(window_start)];
end
if ischar(window_end)
  window_end = [events.(window_end)];
end

blink = window_start < art & art <= window_end;
blink_freq = nnz(blink) / length(blink);

