function [p_recalls] = spc(recalls_matrix, subjects, list_length, ...
			   rec_mask, pres_mask)
%SPC   Serial position curve (recall probability by serial position).
%  
%  p_recall = spc(recalls_matrix, subjects, list_length, rec_mask, pres_mask)
%
%  INPUTS: 
%  recalls_matrix:  a matrix whose elements are serial positions of recalled
%                   items.  The rows of this matrix should represent recalls
%                   made by a single subject on a single trial.
%
%        subjects:  a column vector which indexes the rows of recalls_matrix
%                   with a subject number (or other identifier).  That is, 
%                   the recall trials of subject S should be located in
%                   recalls_matrix(find(subjects==S), :)
%
%     list_length:  a scalar indicating the number of serial positions in the
%                   presented lists.  serial positions are assumed to run 
%                   from 1:list_length.
%
%        rec_mask:  if given, a logical matrix of the same shape as 
%                   recalls_matrix, which is false at positions (i, j) where
%                   the value at recalls_matrix(i, j) should be excluded from
%                   the calculation of the probability of recall.  If NOT
%                   given, a standard clean recalls mask is used, which 
%                   excludes repeats, intrusions and empty cells
% 
%       pres_mask:  if given, a logical matrix of the same shape as the
%                   item presentation matrix (i.e., num_trials x
%                   list_length).  This mask should be true at
%                   positions (t, sp) where an item in the condition
%                   of interest was presented at serial position sp on
%                   trial t; and false everywhere else.  If NOT given,
%                   a blank mask of this shape is used.
% 
%  OUTPUTS:
%        p_recall:  a matrix of probablities.  Its columns are indexed by
%                   serial position and its rows are indexed by subject.
%
%  EXAMPLES:
%  >> recalls = [6 5 3 4 1 0; ...
%                4 2 1 -1 0 0];  
%  >> subjects = [1; 2]; list_length = 6;
%  >> % use a standard mask:
%  >> sp_curve = spc(recalls, subjects, list_length)
%  sp_curve =
%
%   1   0   1   1   1   1
%   1   1   0   1   0   0
%
%  >> % provide a specialized mask:
%  >> mask = (recalls > 0); mask(:, 1:3) = false;
%  >> special_spc = spc(recalls, subjects, list_length, mask)
%  special_spc = 
%
%   1   0   0   1   0   0
%   0   0   0   0   0   0
% 
%  >> % provide a condition mask:
%  >> cmask = true(2, list_length); cmask(:, 4:end) = false;
%  >> pr = spc(recalls, subjects, list_length, mask, cmask)
%  pr = 
%  
%  1   0   0   Inf   NaN   NaN
%  0   0   0   NaN   NaN   NaN

% sanity checks:
if ~exist('recalls_matrix', 'var')
  error('You must pass a recalls matrix.')
elseif ~exist('subjects', 'var')
  error('You must pass a subjects vector.')
elseif ~exist('list_length', 'var')
  error('You must pass a list length.') 
elseif size(recalls_matrix, 1) ~= length(subjects)
  error('recalls matrix must have the same number of rows as subjects.')
end

if ~exist('rec_mask', 'var')
  % create standard clean recalls mask if none was given
  rec_mask = make_clean_recalls_mask2d(recalls_matrix);
elseif size(rec_mask) ~= size(recalls_matrix)
  error('recalls_matrix and rec_mask must have the same shape.')
end

if ~exist('pres_mask', 'var')
  % create a mask for the "standard" condition: all items count.
  pres_mask = true(size(recalls_matrix, 1), list_length);
elseif size(pres_mask, 1) ~= size(recalls_matrix, 1)
  error(['recalls_matrix and pres_mask must have the same number' ...
	 ' of rows'])
elseif size(pres_mask, 2) ~= list_length
  error('pres_mask must have a column for each serial position')
end

% call on the function that does all of the work. this function doesn't
% have any error-checking and assumes all of the inputs are given.
p_recalls = spc_core(recalls_matrix, subjects, list_length, ...
			   rec_mask, pres_mask);