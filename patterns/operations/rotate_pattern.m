function subj = rotate_pattern(subj, pca_pat_name, pat_name, varargin)
%ROTATE_PATTERN   Rotate a pattern to match another pattern's PCA.
%
%  subj = rotate_pattern(subj, pca_pat_name, pat_name, ...)
%
%  INPUTS:
%          subj:  subject object.
%
%  pca_pat_name:  name of an attached pattern of principal components.
%
%      pat_name:  name of a pattern to rotate into the space of the PCA
%                 pattern. Must have the same number of features
%                 (dimensions other than events) as the PCA pattern.
%
%  OUTPUTS:
%          subj:  subject object with either a new pat object, or a
%                 modified pat object, depending on the save params.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   save_mats - if true, and input mats are saved on disk, modified
%               mats will be saved to disk. If false, the modified mats
%               will be stored in the workspace, and can subsequently
%               be moved to disk using move_obj_to_hd. (true)
%   overwrite - if true, existing patterns on disk will be overwritten.
%               (false)
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change. ('')
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.

% input checks
if ~exist('subj', 'var') || ~isstruct(subj)
  error('You must input a subject object.')
end

% get the PCA info from the first pattern
stat = getobj(subj, 'pat', pca_pat_name, 'stat', 'princomp');
load(stat.file);

% get the pattern to modify
pat = getobj(subj, 'pat', pat_name);

% make the new pattern
pat = mod_pattern(pat, @rotate_pat, {res.coeff}, varargin{:});

% add the stats from the first pattern
pat = setobj(pat, 'stat', stat);
subj = setobj(subj, 'pat', pat);

function pat = rotate_pat(pat, coeff)
  pattern = get_mat(pat);
  
  % convert to [obs X vars] format
  pat_size = size(pattern);
  pattern = reshape(pattern, [pat_size(1) prod(pat_size(2:end))]);
  
  % deal with missing data
  pattern = remove_nans(pattern);

  % rotate
  score = bsxfun(@minus, pattern, mean(pattern,1)) * coeff;
  
  % update dimension info
  for i=1:size(score, 2)
    chan_info(i).number = i;
    chan_info(i).region = '';
    chan_info(i).label = sprintf('Component %d', i);
  end
  pat.dim.chan = chan_info;
  pat.dim.time = init_time();
  pat.dim.freq = init_freq();
  
  % set score as the new pattern
  pat = set_mat(pat, score, 'ws');
%endfunction

