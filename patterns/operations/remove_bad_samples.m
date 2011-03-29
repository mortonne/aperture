function pat = remove_bad_samples(pat, varargin)
%REMOVE_BAD_SAMPLES   Remove parts of a pattern that contain NaNs.
%
%  Some functions reject samples of a pattern by changing elements to
%  NaN. This function then allows one to remove NaN'd parts of a pattern
%  completely.
%
%  pat = remove_bad_samples(pat, ...)
%
%  INPUTS:
%     pat:  pattern object.
%
%  OUTPUTS:
%      pat:  pattern object with bad dimension elements removed,
%            according to options (see below).
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   dims:     - specifies which dimensions to check. May be a vector of
%               dimension numbers or a cell array of dimension names
%               ('ev', 'chan', 'time', or 'freq'). (1:4)
%   remove_if - specifies when to remove a dimension element from the
%               pattern.
%                'all' remove a dimension element if all samples (e.g.
%                      all channels and times for a given event) are
%                      NaN. (default)
%                'any' remove a dimension element if any samples are
%                      NaN.
%   save_mats - if true, and input mats are saved on disk, modified
%               mats will be saved to disk. If false, the modified
%               mats will be stored in the workspace, and can
%               subsequently be moved to disk using move_obj_to_hd.
%               (true)
%   overwrite - if true, existing patterns on disk will be
%               overwritten. (false)
%   save_as   - string identifier to name the modified pattern. If
%               empty, the name will not change. ('')
%   res_dir   - directory in which to save the modified pattern and
%               events, if applicable. Default is a directory named
%               pat_name on the same level as the input pat.

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

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% default params
defaults.dims = 1:4;
defaults.remove_if = 'all';
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @remove_samples, {params}, saveopts);

function pat = remove_samples(pat, params)
  pattern = get_mat(pat);

  % find "bad" samples
  all_ind = repmat({':'}, 1, ndims(pattern));
  to_keep = all_ind;
  for i = 1:length(params.dims)
    % get the dimension name and number
    if isnumeric(params.dims)
      this_dim = params.dims(i);
    elseif iscellstr(params.dims)
      this_dim = params.dims{i};
    else
      error('Invalid dims input.')
    end
    [dim_name, dim_number] = read_dim_input(this_dim);
    
    % find elements that match the criteria
    isdimbad = truth_other(isnan(pattern), dim_number, params.remove_if);
    to_keep{dim_number} = ~isdimbad;
    
    % fix the dimension info
    dim = get_dim(pat.dim, dim_name);
    pat.dim = set_dim(pat.dim, dim_name, dim(~isdimbad), 'ws');
  end
  
  % apply all dimension logicals simultaneously to index the pattern
  pattern = pattern(to_keep{:});
  if isempty(pattern)
    error('all samples removed from pattern.')
  end
  
  pat = set_mat(pat, pattern, 'ws');

