function subj = zscore_pattern(subj, pat_name, base_pat_name, varargin)
%ZSCORE_PATTERN   Z-score a pattern compared to a baseline.
%
%  To z-score a pattern, first define a baseline pattern and add it to
%  the subj object. Baseline statistics (mean and std. dev.) will be
%  calculated from the baseline pattern for each event bin, channel, and
%  frequency, and used to zscore the corresponding bin in the
%  pattern. The default is to zscore each session separately (requires a
%  'session' field on the events associated with both patterns). This
%  may be customized by defining alternate event bins using
%  params.event_bins.
%
%  If the standard deviation for an event bin is 0, the zscores for that
%  bin will be NaN.
%
%  subj = zscore_pattern(subj, pat_name, base_pat_name, ...)
%
%  INPUTS:
%           subj:  a subject object.
%
%       pat_name:  pattern to be z-transformed.
%
%  base_pat_name:  pattern to use for calculating the baseline.
%                  Alternatively, may be a range of millisecond times in
%                  the form of [start end] specifying a period of the
%                  pattern to use as baseline.
%
%  OUTPUTS:
%           subj:  subject object with a modified or added pattern (see
%                  params for save options).
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_bins - input to make_event_bins; used to define subsets of
%                events to separately calculate the z-score for.
%                ('session')
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

% options
defaults.event_bins = 'session';
[params, save_opts] = propval(varargin, defaults);

% get baseline pattern and events
pat = getobj(subj, 'pat', pat_name);
if ischar(base_pat_name)
  base_pat = getobj(subj, 'pat', base_pat_name);
  diff_events = true;
else
  base_pat = filter_pattern(pat, 'time_filter', base_pat_name, ...
                            'save_mats', false, 'verbose', false);
  diff_events = false;
end

% sanity check
if patsize(pat.dim, 2) ~= patsize(base_pat.dim, 2)
  error('Pattern and base pattern have different numbers of channels.')
elseif patsize(pat.dim, 4) ~= patsize(base_pat.dim, 4)
  error('Pattern and base pattern have different numbers of frequencies.')
end

% load the base pattern and corresponding events
base_pattern = get_mat(base_pat);
base_events = get_dim(base_pat.dim, 'ev');  

% apply the z-transform for each event_bin, channel, and frequency
subj = apply_to_pat(subj, pat_name, @mod_pattern, ...
                    {@apply_zscore, ...
                    {base_pattern, base_events, ...
                    params.event_bins, diff_events}, ...
                    save_opts});


function pat = apply_zscore(pat, base_pattern, base_events, ...
                            event_bin_defs, diff_events)

  [n_events, n_chans, n_time, n_freq] = size(base_pattern);

  % baseline event bins
  base_event_bins = index2bins(make_event_index(base_events, ...
                                                event_bin_defs));
  n_bins = length(base_event_bins);

  % get baseline statistics
  m = NaN(n_bins, n_chans, 1, n_freq);
  s = NaN(n_bins, n_chans, 1, n_freq);
  for i = 1:n_bins
    % samples of interest
    base_ind = {base_event_bins{i},':',':',':'};

    % within this bin, average over events and time
    % gives [1 X chans X 1 X freqs]
    m(i,:,:,:) = nanmean(nanmean(base_pattern(base_ind{:}), 1), 3);
    
    % take std dev over events, average over time
    s(i,:,:,:) = nanmean(nanstd(base_pattern(base_ind{:}), 1), 3);
  end
  clear base_pattern

  % apply z-transform
  if diff_events
    % pattern events may be different from baseline; calculate
    % indices separately
    events = get_dim(pat.dim, 'ev');
    event_bins = index2bins(make_event_index(events, event_bin_defs));
  else
    % same events, so can use the same bins as baseline
    event_bins = base_event_bins;
  end
  
  pattern = get_mat(pat);
  n_time = size(pattern, 3);
  for i = 1:n_bins
    % samples of interest
    ind = {event_bins{i},':',':',':'};
    
    % transformation is the same for each event (within this bin) and time
    rep_ind = [length(event_bins{i}) 1 n_time 1];
    pattern(ind{:}) = (pattern(ind{:}) - repmat(m(i,:,:,:), rep_ind)) ...
                       ./ repmat(s(i,:,:,:), rep_ind);
  end
  
  % remove z-scores corresponding to sd=0
  pattern(isinf(pattern)) = NaN;

  % return the transformed pattern
  pat = set_mat(pat, pattern, 'ws');

