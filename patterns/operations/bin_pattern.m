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
%   f              - function handle to apply to each bin. (@nanmean)
%   f_inputs       - cell array of additional inputs to f. ({})
%   eventbins      - see make_event_bins for allowed formats. ([])
%   eventbinlabels - cell array of strings, with one cell per bin. Gives
%                    a label for each event bin. ({})
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
%   min_samp       - minimum number of samples required to calculate the
%                    mean for a given bin. If there are fewer samples in
%                    a bin than min_samp, the mean for that bin will be
%                    NaN. ([])
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
defaults.f = @nanmean;
defaults.f_inputs = {};
defaults.eventbins = [];
defaults.eventbinlabels = {};
defaults.eventbinlevels = {};
defaults.timebins = [];
defaults.timebinlabels = {};
defaults.chanbins = [];
defaults.chanbinlabels = {};
defaults.freqbins = [];
defaults.freqbinlabels = {};
defaults.min_samp = [];
[params, saveopts] = propval(varargin, defaults);

% make the new pattern
pat = mod_pattern(pat, @apply_pat_binning, {params}, saveopts);

function pat = apply_pat_binning(pat, params)
  pattern = get_mat(pat);  
  
  % apply the bins to the pat object
  p = rmfield(params, {'f' 'f_inputs'});
  [pat, bins] = patBins(pat, p);
  
  % average within bins in the pattern
  pattern = patMeans(pattern, bins, params.f, params.f_inputs{:});
  
  pat = set_mat(pat, pattern, 'ws');
%endfunction

