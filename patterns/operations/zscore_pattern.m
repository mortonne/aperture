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
%  subj = zscore_pattern(subj, pat_name, base_pat_name, ...)
%
%  INPUTS:
%           subj:  a subject object.
%
%       pat_name:  pattern to be z-transformed.
%
%  base_pat_name:  pattern to use for calculating the baseline.
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

% options
defaults.event_bins = 'session';
[params, save_opts] = propval(varargin, defaults);

% get baseline pattern and events
base_pat = getobj(subj, 'pat', base_pat_name);
base_pattern = get_mat(base_pat);
base_events = get_dim(base_pat.dim, 'ev');  

% get subsets of events to calculate baseline for
base_event_bins = index2bins(make_event_bins(base_events, params.event_bins));

% get mean and std. dev. for each event_bin, channel, and frequency.
% if there are multiple time samples in each baseline event, calculate
% for each sample, then average across time
iter_cell = {base_event_bins, 'iter', [], 'iter'};
m = apply_by_group(@(x) nanmean(nanmean(x, 1), 3), {base_pattern}, iter_cell);
s = apply_by_group(@(x) nanmean(nanstd(x, 1), 3), {base_pattern}, iter_cell);

% apply the z-transform for each event_bin, channel, and frequency
subj = apply_to_pat(subj, pat_name, @mod_pattern, ...
                    {@apply_zscore, {base_pattern, m, s, params.event_bins}, save_opts});

function pat = apply_zscore(pat, base_pattern, m, s, event_bin_defs)
  % use same subsets of events used for calculating baseline
  events = get_dim(pat.dim, 'ev');
  event_bins = index2bins(make_event_bins(events, event_bin_defs));
  iter_cell = {event_bins, 'iter', [], 'iter'};
  
  % z-transform all samples for each event_bin, channel, and frequency
  pattern = get_mat(pat);
  [n_events, n_chans, n_time, n_freq] = size(pattern);
  for i=1:length(event_bins)
    for j=1:n_chans
      for k=1:n_freq
        ind = {event_bins{i},j,':',k};
        
        %below we try and deal with situations where most of the
        %baseline observations are NaNd out, which results in small
        %standard deviations and huge Zscores
        %if s(i,j,:,k) < .5
        %  pattern(ind{:}) = NaN;
        %else
        %  pattern(ind{:}) = (pattern(ind{:}) - m(i,j,:,k)) / s(i,j,:,k);
        %end
        
        %below is an attempt to improve upon the above sanity/check
        %and fix. ideal would be a percentage threshold for the number
        %of observations in the baseline period, that if not met
        %would result in that event being excluded
        %need to make sure the first statement is properly indexed

        %if mean(isnan(base_pattern(ind{:})))>(1/3)
        %  pattern(ind{:}) = NaN;
        %elseif s(i,j,:,k) < .5
        %pattern(ind{:}) = NaN;
        %else
        pattern(ind{:}) = (pattern(ind{:}) - m(i,j,:,k)) / s(i,j,:,k);
        %end
        
      end
    end
  end
  
  % return the transformed pattern
  pat = set_mat(pat, pattern, 'ws');

