function subj = update_pat_chans(subj, pat_names)
%UPDATE_PAT_CHANS   Update channel information for a subject's patterns.
%
%  subj = update_pat_chans(subj, pat_names)
%
%  INPUTS:
%       subj:  a subject object.
%
%  pat_names:  optional: if not specified, all patterns will be updated.
%
%  OUTPUTS:
%       subj:  subject object with updated patterns.

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

if ~exist('pat_names', 'var')
  pat_names = {subj.pat.name};
end

chan = get_dim(subj, 'chan');
chan_numbers = [chan.number];
chan_fields = fieldnames(chan);
for i=1:length(pat_names)
  pat = getobj(subj, 'pat', pat_names{i});
  pat_chan = get_dim(pat.dim, 'chan');
  
  % get intersection on the basis of channel numbers
  pat_numbers = [pat_chan.number];
  [c, ia, ib] = intersect(chan_numbers, pat_numbers);

  % get fields to update
  pat_fields = fieldnames(pat_chan);
  shared = setdiff(intersect(chan_fields, pat_fields), {'number'});
  
  % update all intersecting fields
  for j=1:length(shared)
    [pat_chan(ib).(shared{j})] = chan(ia).(shared{j});
  end
  
  % update the pattern object
  pat.dim = set_dim(pat.dim, 'chan', pat_chan);
  subj = setobj(subj, 'pat', pat);
end

