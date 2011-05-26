function pat = remove_small_samples(pat, id_bin, event_bins, min_n, varargin)
%REMOVE_SMALL_SAMPLES   Remove subjects with too few samples in a bin.
%
%  Designed to remove subjects from patterns containing multiple
%  subjects before running repeated-measures analysis.
%
%  pat = remove_small_samples(pat, id_bin, event_bins, min_n, ...)
%
%  INPUTS:
%         pat:  pattern object.
%
%      id_bin:  bin definition specifying unique individuals in the
%               pattern. See make_event_index for allowed formats.
%
%  event_bins:  definitions for each event bin to examine.
%
%       min_n:  minimum number of events each individual must have in
%               each bin.
%
%  OUTPUTS:
%         pat:  pattern with individuals removed if they have too few
%               samples.
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

pat = mod_pattern(pat, @run_remove_samples, {id_bin, event_bins, min_n}, ...
                  varargin);


function pat = run_remove_samples(pat, id_bin, event_bins, min_n)

% load pattern events
events = get_dim(pat.dim, 'ev');

% get bin indices
[ids, id_strs] = make_event_index(events, id_bin);
uids = unique(ids);
bad = false(1, length(uids));

% get all values of bins in the pattern. We don't know the expected
% number of bins, so if all individuals are missing a given bin, they
% will all be left in
[temp, bins] = patBins(pat, 'eventbins', [id_bin event_bins]);

% remove individuals that don't have an entry for each bin
id_n_bins = cellfun(@length, bins{1});
n_bins = max(id_n_bins);
bad = bad | (id_n_bins < n_bins);

% check whether any N is less than minimum
id_min_n = apply_by_index(@(x) min([x.n]), ids, 1, {events'});
bad = bad | (id_min_n' < min_n);
bad_ids = find(bad);

if any(bad)
  fprintf('Removing %d subjects with less than %d samples per bin: ', ...
          nnz(bad), min_n)
  for i = 1:length(bad_ids)
    fprintf('%s ', id_strs{bad_ids(i)})
  end
  fprintf('\n')
end

% IDs will be one-indexed, so position in bad vector gives the ID
bad_events = ismember(ids, bad_ids);

% filter events
filt_events = events(~bad_events);
pat.dim = set_dim(pat.dim, 'ev', filt_events, 'ws');

% filter pattern
pattern = get_mat(pat);
pattern = pattern(~bad_events,:,:,:);
pat = set_mat(pat, pattern, 'ws');

