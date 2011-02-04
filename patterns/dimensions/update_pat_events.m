function subj = update_pat_events(subj, ev_name, pat_name)
%UPDATE_PATTERN_EVENTS   Update events associated with a pattern.
%
%  Update the events associated with a pattern or patterns. The new
%  events will be merged with the pattern events using update_struct.
%
%  subj = update_pattern_events(subj, ev_name, pat_name)
%
%  INPUTS:
%      subj:  a subject object.
%
%   ev_name:  name of the events to use for updating the pattern events.
%
%  pat_name:  name of the pattern whose events will be updated. May end
%             with a wildcard (*); if this is the case, all patterns
%             whose name matches will be updated.
%
%  OUTPUTS:
%      subj:  updated subject object.

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

% load the events
new_events = get_mat(getobj(subj, 'ev', ev_name));

% find matching patterns
if strcmp(pat_name(end), '*')
  pat_names = {subj.pat.name};
  match = strmatch(pat_name(1:end-1), pat_names);
  pat_names = pat_names(match);
else
  pat_names = {pat_name};
end

for i=1:length(pat_names)
  if length(pat_names) > 1
    fprintf('%s\n', pat_names{i})
  end
  
  % get the pattern's events
  pat = getobj(subj, 'pat', pat_names{i});
  pat_events = get_dim(pat.dim, 'ev');
  %updated_events = update_struct(pat_events, new_events, ...
  %                               {'eegfile', 'eegoffset'});
  
  % update the pattern events
  updated_events = update_struct(pat_events, new_events, ...
                                 {'mstime','type'});
  pat.dim.ev = set_mat(pat.dim.ev, updated_events);
  
  % update the pat object
  subj = setobj(subj, 'pat', pat);
end

