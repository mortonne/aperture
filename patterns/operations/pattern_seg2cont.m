function pat = pattern_seg2cont(pat, varargin)
%PATTERN_SEG2CONT   Convert a segmented pattern to continuous form.
%
%  pat = pattern_seg2cont(pat, ...)
%
%  INPUTS:
%      pat:  input pattern object.
%
%  OUTPUTS:
%      pat:  pattern reshaped to be continuous. Events have an added
%            "time" field giving the time of each event.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
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

% options
defaults = struct;
[params, saveopts] = propval(varargin, defaults);

% run seg2cont
pat = mod_pattern(pat, @run_seg2cont, {params}, saveopts);

function pat = run_seg2cont(pat, params)

  % load the pattern
  pattern = get_mat(pat);
  
  % reshape to have events X time
  [n_events, n_chans, n_times, n_freqs] = size(pattern);
  pattern = reshape(permute(pattern, [3 1 2 4]), ...
                    [n_events * n_times n_chans 1 n_freqs]);
  pat = set_mat(pat, pattern, 'ws');
  
  % create new events with a time field
  times = get_dim_vals(pat.dim, 'time');
  events = get_dim(pat.dim, 'ev');
  
  new_events = [];
  times_cell = num2cell(times);
  for i = 1:n_events
    time_events = repmat(events(i), 1, n_times);
    [time_events.time] = times_cell{:};
    new_events = [new_events time_events];
  end
  
  pat.dim.ev = set_mat(pat.dim.ev, new_events, 'ws');
  pat.dim.ev.modified = true;
  pat.dim = set_dim(pat.dim, 'time', init_time);
  
