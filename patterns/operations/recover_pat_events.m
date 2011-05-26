function subj = recover_pat_events(subj, pat_name, varargin)
%RECOVER_PAT_EVENTS   Fix broken event file reference in a pattern.
%
%  If events have been accidentally deleted from a pattern, they can be
%  recreated from the source events structure. This assumes that no
%  events have been added to the source events, and that filterStruct
%  will return them in the same order as during the original pattern
%  creation. In most cases, these assumptions should be correct. An
%  error will be thrown if events have the wrong length after applying
%  the filter.
%
%  subj = recover_pat_events(subj, pat_name, ...)
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   ev_name      - name of the source events structure for the pattern.
%                  (pat.params.evname)
%   event_filter - filter to apply to the source events to match the
%                  pattern. (pat.params.eventFilter)

pat = getobj(subj, 'pat', pat_name);

% options
defaults.ev_name = pat.params.evname;
defaults.event_filter = pat.params.eventFilter;
params = propval(varargin, defaults);

% get filtered events
events = get_mat(getobj(subj, 'ev', params.ev_name));
filt_events = filterStruct(events, params.event_filter);

% get the pattern
if length(filt_events) ~= patsize(pat.dim, 'ev')
  error('number of events does not match pattern.')
end

% save the events in the standard file
ev_file = fullfile(get_pat_dir(pat, 'events'), ...
                   objfilename('events', pat.name, pat.source));
if exist('ev_file', 'file')
  error('events file already exists: %s\n', ev_file)
end
pat.dim.ev.file = ev_file;
pat.dim = set_dim(pat.dim, 'ev', filt_events, 'hd');

% change the pattern to point to the new events
subj = setobj(subj, 'pat', pat);

