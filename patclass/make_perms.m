function perms = make_perms(n_perm, n_obs, varargin)
%MAKE_PERMS   Make indices for a permutation test.
%
%  perms = make_perms(n_perm, n_obs, ...)
%
%  PARAMS:
%   group_index - numeric vector of length n_obs, where each unique
%                 value labels one group that should be treated as a
%                 unit for scrambling purposes. ([])
%   iter_index  - each unique value labels one group within which
%                 observations will be scrambled. ([])

% options
defaults.group_index = [];
defaults.iter_index = [];
params = propval(varargin, defaults);

if ~isempty(params.iter_index)
  if n_obs ~= length(params.iter_index)
    error('iter_index must be of length n_obs')
  end
  
  perms = NaN(n_perm, n_obs);
  uindex = unique(params.iter_index);
  for i = 1:length(uindex)
    % original place of these observations
    orig_index = find(params.iter_index == uindex(i));
    
    % permute within
    if ~isempty(params.group_index)
      perm_within = make_perms(n_perm, length(orig_index), ...
                               'group_index', params.group_index(orig_index));
    else
      perm_within = make_perms(n_perm, length(orig_index));
    end
    
    % use the permutation to index the originals,
    % place the perms within the larger set of observations
    perms(:,orig_index) = orig_index(perm_within);
  end

elseif ~isempty(params.group_index)
  % fill in NaNs
  nan_index = isnan(params.group_index);
  start = max(params.group_index) + 1;
  finish = start + nnz(nan_index) - 1;
  params.group_index(nan_index) = start:finish;

  % get the start index of each group
  perms = NaN(n_perm, n_obs);
  uindex = unique(params.group_index);
  start_index = NaN(length(uindex), 1);
  for i = 1:length(uindex)
    start_index(i) = find(params.group_index == uindex(i), 1);
  end
  
  % permute the group (start) indices
  perm_group = make_perms(n_perm, length(uindex));
  perm_start = start_index(perm_group);
  for i = 1:length(uindex)
    match = params.group_index == uindex(i);
    perms(:,match) = repmat(perm_start(:,i), 1, nnz(match));
  end
  
else
  perms = randperm2(n_perm, n_obs);
end

