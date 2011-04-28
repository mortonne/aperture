function pat = bin_pattern(pat, varargin)
%BIN_PATTERN   Average over bins of a pattern.
%
%  Average over arbitrary bins along one or more dimensions of a
%  pattern. For example, you can average over subsets of events,
%  average within frequency bands or average over all channels in a
%  region.
%
%  pat = bin_pattern(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  binned pattern object, with updated pattern matrix and
%            associated metadata.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   f              - function handle to apply to each bin.
%                    (@nanmean)
%   f_inputs       - cell array of additional inputs to f. ({})
%   eval_by        - how to evaluate the function:
%                     'dim' (default) evaluate one dimension at a time.
%                           f must take a second input that indicates
%                           the dimension to process along (e.g.
%                           nanmean). This method is usually faster.
%                           Called as: y = f(x, dim, f_inputs{:})
%                     'bin' evaluate one bin at a time. f should be able
%                           to handle matrix input and output a scalar.
%                           Called as: y = f(x, f_inputs{:})
%   eventbins      - see make_event_bins for allowed formats. ([])
%   eventbinlabels - cell array of strings, with one cell per bin. Gives
%                    a label for each event bin. ({})
%   eventbinlevels - cell array of cell arrays of strings. Used only if
%                    specifying bins as a conjunction of multiple
%                    factors, e.g. two events fields. The label for
%                    factor i, level j goes in eventbinlevels{i}{j}.
%                    ({})
%   chanbins       - cell array where chanbins{i} defines bin i. Each
%                    cell may contain an array of channel numbers, a
%                    cell array of channel labels, or a string to be
%                    passed in inStruct as "expr". ([])
%   chanbinlabels  - cell array of strings indicating channel bin
%                    labels. ({})
%   timebins       - [bins X 2] array, where timebins(i,1) gives the
%                    start time in milliseconds of bin i, and
%                    timebins(i,2) gives the end of the bin. ([])
%   timebinlabels  - cell array of strings giving a label for each time
%                    bin. ({})
%   freqbins       - [bins X 2] array, where freqbins(i,1) gives the
%                    start frequency in Hz of bin i, and freqbins(i,2)
%                    gives the end of the bin. ([])
%   freqbinlabels  - cell array of strings giving a label for each
%                    frequency bin. ({})
%   save_mats      - if true, and input mats are saved on disk, modified
%                    mats will be saved to disk. If false, the modified
%                    mats will be stored in the workspace, and can
%                    subsequently be moved to disk using move_obj_to_hd.
%                    (true)
%   overwrite      - if true, existing patterns on disk will be
%                    overwritten. (false)
%   save_as        - string identifier to name the modified pattern. If
%                    empty, the name will not change. ('')
%   res_dir        - directory in which to save the modified pattern and
%                    events, if applicable. Default is a directory named
%                    pat_name on the same level as the input pat.

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
defaults.f = @nanmean;
defaults.f_inputs = {};
defaults.eval_by = 'dim';
defaults.eventbins = [];
defaults.eventbinlabels = {};
defaults.eventbinlevels = {};
defaults.timebins = [];
defaults.timebinlabels = {};
defaults.chanbins = [];
defaults.chanbinlabels = {};
defaults.freqbins = [];
defaults.freqbinlabels = {};
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @apply_pat_binning, {params}, saveopts);

function pat = apply_pat_binning(pat, params)
  
  pattern = get_mat(pat);

  % apply the bins to the pat object
  p = rmfield(params, {'f' 'f_inputs' 'eval_by'});
  [pat, bins] = patBins(pat, p);
  
  if all(cellfun(@isempty, bins))
    % no binning happened; nothing to do
    pat = set_mat(pat, pattern, 'ws');
    return
  end
  
  switch params.eval_by
   case 'dim'
    if ~ismember(func2str(params.f), {'mean' 'nanmean'})
      warning('Applying f by dimension.')
    end
    
    % apply f along one dimension at at time
    pattern = patMeans(pattern, bins, params.f);
    
   case 'bin'
    % apply f within bins in the pattern
    [bins{cellfun(@isempty, bins)}] = deal('iter');
    pattern = apply_by_group(params.f, {pattern}, bins, params.f_inputs);
    
   otherwise
    error('Invalid eval_by input.')
  end
  
  pat = set_mat(pat, pattern, 'ws');

