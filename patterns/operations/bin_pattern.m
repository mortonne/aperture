function pat = bin_pattern(pat, varargin)
%BIN_PATTERN   Average over bins of a pattern.
%
%  Average over arbitrary bins along one or more dimensions of a
%  pattern. For example, you can average within frequency bands or
%  average over all channels in a region.
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
%   eventbins      - see make_event_bins for allowed formats. ([])
%   eventbinlabels - cell array of strings, with one cell per bin. Gives
%                    a label for each event bin. ({})
%   chanbins       - see patBins for allowed formats. ([])
%   chanbinlabels  - cell array of strings indicating channel bin
%                    labels. ({})
%   timebins       - [bins X 2] array, where timebins(X,1) gives the
%                    start time in milliseconds of bin X, and
%                    timebins(X,2) gives the end of the bin. ([])
%   timebinlabels  - cell array of strings giving a label for each time
%                    bin. ({})
%   freqbins       - [bins X 2] array, where freqbins(X,1) gives the
%                    start frequency in Hz of bin X, and freqbins(X,2)
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

% input checks
if ~exist('pat', 'var') || ~isstruct(pat)
  error('You must input a pattern object.')
end

% default params
defaults.eventbins = [];
defaults.eventbinlabels = {};
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

  % backwards compatibility
  p = params;
  p.MSbins = params.timebins;
  p.MSbinlabels = params.timebinlabels;
  p = rmfield(p, {'timebins', 'timebinlabels'});
  
  % apply the bins to the pat object
  [pat, bins] = patBins(pat, p);
  
  % average within bins in the pattern
  pattern = patMeans(pattern, bins);
  
  pat = set_mat(pat, pattern, 'ws');
%endfunction

