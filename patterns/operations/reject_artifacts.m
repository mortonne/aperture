function pat = reject_artifacts(pat, varargin)
%REJECT_ARTIFACTS   Remove artifacts from a pattern.
%
%  pat = reject_artifacts(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUT:
%      pat:  output pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   abs_thresh - if the absolute value of any element of an event
%                crosses this value, the event will be excluded. ([])
%   blink_thresh - if the absolute value of the eog chan diff of
%                 any element of an event crosses this value, the
%                 event will be excluded. ([])
%   reject_full- if true, will reject entire events with blinks (true)
%   k_thresh   - if an event's distribution over time has a value
%                exceeding this value, the event will be excluded. ([])
%   bad_chans  - if true, will find bad channels. (false)
%   veog_chans - vertical eye movement channels. ({[8 126],[25 127]})
%   heog_chans - horizontal eye movement channels. ([1 32])
%   verbose    - if true, information about excluded samples will be
%                displayed. (false)
%   reject     - string identifying whether you want to reject
%                artifacts ('bad') or non-artifact trials ('good').
%                ('bad')
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
defaults.abs_thresh = [];
defaults.blink_thresh = [];
defaults.reject_full = true;
defaults.k_thresh = [];
defaults.bad_chans = false;
defaults.veog_chans = {[8 126],[25 127]};
defaults.heog_chans = [1 32];
defaults.verbose = false;
defaults.reject = 'bad';
defaults.buffer = true;
[params, save_opts] = propval(varargin, defaults);

pat = mod_pattern(pat, @run_reject, {params}, save_opts);

function pat = run_reject(pat, params)
  if params.verbose
    fprintf('\n')
  end

  pattern = get_mat(pat);
  
  % initilize a bad samples mask
  bad = false(size(pattern));
  
  % kurtosis
  if ~isempty(params.k_thresh)
    bad = bad | reject_kurtosis(pattern, params.k_thresh, ...
                                'verbose', params.verbose);
  end

  % absolute value
  if ~isempty(params.abs_thresh)
    bad = bad | reject_threshold(pattern, params.abs_thresh, ...
                                 'verbose', params.verbose);
  end
  
  
  % blink detection - it's ugly because of the way the defaults are defined
  if ~isempty(params.blink_thresh)
    %vertical eog chan blink detection
    if iscell(params.veog_chans)
      bad = bad | reject_blinks(pattern, params.blink_thresh, ...
                                'verbose', params.verbose, 'chans', ...
                                params.veog_chans{1}, 'reject_full', ...
                                params.reject_full);
      if length(params.veog_chans)==2
        bad = bad | reject_blinks(pattern, params.blink_thresh, ...
                                'verbose', params.verbose, 'chans', ...
                                params.veog_chans{2}, 'reject_full', ...
                                  params.reject_full);
      end
    else
      bad = bad | reject_blinks(pattern, params.blink_thresh, ...
                                'verbose', params.verbose, 'chans', ...
                                params.veog_chans, 'reject_full', ...
                                params.reject_full);
    end
    %horizontal eog chan blink detection
    bad = bad | reject_blinks(pattern, params.blink_thresh, ...
                              'verbose', params.verbose, 'chans', ...
                              params.heog_chans, 'reject_full', ...
                              params.reject_full);
  end
  
  
  % channels with poor contact
  if params.bad_chans
    events = get_dim(pat.dim, 'ev');
    channels = get_dim_vals(pat.dim, 'chan');
    mask = bad_channels(events, channels, params.heog_chans, ...
                        params.veog_chans);
    mask = repmat(mask, [1 1 size(pattern,3) size(pattern,4)]);
    bad = bad | mask;
  end
  
  switch params.reject
   case 'bad'
    % nan out bad samples
    pattern(bad) = NaN;
   case 'good'
    % nan out good samples
    pattern(~bad) = NaN;
   otherwise
    %some invalid value
    error('please choose either ''bad'' or ''good'' for params.reject')
  end
  
  pat = set_mat(pat, pattern, 'ws');
%endfunction
