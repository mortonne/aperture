function pat = diff_pattern(pat, varargin)
%DIFF_PATTERN   Take differences between elements of a pattern.
%
%  pat = diff_pattern(pat, ...)
%
%  Currently, only takes differences between channels. Later, can expand
%  to take pairs of indices (or vals?) along any dimension.
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  modified pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   chans      - cell array of [1 X 2] arrays of channel numbers.
%                Difference will be chans(1) - chans(2).
%   chanlabels - cell array of strings with labels for each pair of
%                channels. ({})
%   save_mats  - if true, and input mats are saved on disk, modified
%                mats will be saved to disk. If false, the modified mats
%                will be stored in the workspace, and can subsequently
%                be moved to disk using move_obj_to_hd. (true)
%   overwrite  - if true, existing patterns on disk will be overwritten.
%                (false)
%   save_as    - string identifier to name the modified pattern. If
%                empty, the name will not change. ('')
%   res_dir    - directory in which to save the modified pattern and
%                events, if applicable. Default is a directory named
%                pat_name on the same level as the input pat.

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
defaults.eventbins = [];
defaults.eventbinlabels = {};
defaults.eventbinlevels = {};
defaults.weights = [];
defaults.chans = {};
defaults.chanlabels = {};
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
if ~isempty(params.eventbins)
  pat = mod_pattern(pat, @get_evdiffs, {params}, saveopts);
end
if ~isempty(params.chans)
  pat = mod_pattern(pat, @get_chandiffs, {params}, saveopts);
end

function pat = get_evdiffs(pat, params)
  def.eventbins = [];
  def.eventbinlabels = {};
  def.eventbinlevels = {};
  def.weights = [];
  [params, ~] = propval(params, def);
  
  % default for weights with 2 bins, difference; [1 -1]
  if isempty(params.weights) && iscell(params.eventbins) && ...
        length(params.eventbins) == 2
    params.weights = [1 -1];
  end
    
  pattern = get_mat(pat);
  
  % apply the bins to the pat object
  p = rmfield(params, {'weights'});
  [pat, bins] = patBins(pat, p);
  
  if ~all(cellfun(@isempty, bins))
    % binning happened; apply to pattern
    pattern = patMeans(pattern, bins, @nanmean);
  end
  
  s = patsize(pat.dim);
  new_pattern = NaN(1, s(2), s(3), s(4));
  
  % linear combination
  if ~isempty(params.weights)
    new_pattern = params.weights(1).*pattern(1,:,:,:);
    
    for w=2:length(params.weights)
      new_pattern = params.weights(w).*pattern(w,:,:,:) + new_pattern;
    end
    
    % update events to reflect operation across bins
    p2.eventbins = 'overall';
    [pat, bins ] = patBins(pat, p2);
    
  else
    % no weights, just keep old pattern
    new_pattern = pattern;
  end
  
  pat = set_mat(pat, new_pattern, 'ws');

function pat = get_chandiffs(pat, params)
  def.chans = {};
  def.chanlabels = {};
  [params, ~] = propval(params, def);
  
  pattern = get_mat(pat);
  
  s = patsize(pat.dim);
  new_pattern = nan(s(1), length(params.chans), s(3), s(4));
  channels = get_dim_vals(pat.dim, 'chan');
  
  for i = 1:length(params.chans)
    diff_chans = params.chans{i};
    
    % find the channels
    chan_ind = [find(channels==diff_chans(1)) find(channels==diff_chans(2))];
    if length(chan_ind)~=2
      error('channels not found.')
    end
    
    % take the difference
    new_pattern(:,i,:,:) = pattern(:,chan_ind(1),:,:) - ...
                           pattern(:,chan_ind(2),:,:);
    
    % fix dimension info
    if isempty(params.chanlabels)
      label = sprintf('%d - %d', diff_chans(1), diff_chans(2));
    else
      label = params.chanlabels{i};
    end
    chan_info(i) = struct('number', diff_chans, 'label', label);
  end
  pat.dim = set_dim(pat.dim, 'chan', chan_info, 'ws');
  pat = set_mat(pat, new_pattern, 'ws');
%endfunction
