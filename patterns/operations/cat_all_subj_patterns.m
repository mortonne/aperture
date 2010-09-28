function pat = cat_all_subj_patterns(subj, pat_name, dimension, varargin)
%CAT_ALL_SUBJ_PATTERNS   Concatenate subject patterns into one pattern.
%
%  pat = cat_all_subj_patterns(subj, pat_name, dimension, ...)
%
%  INPUTS:
%       subj:  a vector of subject objects.
%
%   pat_name:  name of the pattern to concatenate.
%
%  dimension:  the dimension to concatenate along.
%
%  Additional inputs will be passed to cat_patterns.
%
%  OUTPUTS:
%        pat:  new pattern object.

pats = getobjallsubj(subj, {'pat', pat_name});
pat = cat_patterns(pats, dimension, varargin);

