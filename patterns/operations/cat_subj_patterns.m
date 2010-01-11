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

% get all the pat objects to concatenate
pats = [];
for i=1:length(pat_names)
  pats = addobj(pats, getobj(subj, 'pat', pat_names{i}));
end

% concatenate
pat = cat_patterns(pats, dimension, varargin{:});

% add the new pattern to subj
subj = setobj(subj, 'pat', pat);
