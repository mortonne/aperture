function subj = cat_subj_patterns(subj, dimension, pat_names, varargin)
%CAT_SUBJ_PATTERNS   Concatenate patterns for one subject.
%
%  subj = cat_subj_patterns(subj, dimension, pat_names, ...)
%
%  Calls cat_patterns to concatenate all subject patterns listed in
%  pat_names.  Additional inputs will be passed to cat_patterns.
%
%  INPUTS:
%          subj:  a subject object.
%
%     dimension:  the dimension to concatenate along.
%
%     pat_names:  cell array of strings with the names of the patterns
%                 to concatenate.
%
%  OUTPUTS:
%          subj:  subject object with a new pattern with the
%                 concatenated patterns.

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

% get all the pat objects to concatenate
pats = [];
for i=1:length(pat_names)
  pats = addobj(pats, getobj(subj, 'pat', pat_names{i}));
end

% concatenate
pat = cat_patterns(pats, dimension, varargin{:});

% add the new pattern to subj
subj = setobj(subj, 'pat', pat);
