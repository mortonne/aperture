function pat = grand_average(subj, pat_name, varargin)
%GRAND_AVERAGE   Calculate an average across patterns from multiple subjects.
%
%  Used to calculate an average across subjects for a given pattern
%  type. The pattern indicated by pat_name must have the same dimensions
%  for each subject. Events may be averaged prior to averaging across
%  subjects by setting the event_bins param.
%
%  pat = grand_average(subj, pat_name, ...)
%
%  INPUTS:
%      subj:  vector structure holding information about subjects. Each
%             must contain a pat object named pat_name.
%
%  pat_name:  name of the pattern to concatenate across subjects.
%
%  OUTPUTS:
%       pat:  new pattern object.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   event_bins - definition of event bins to average over before
%                averaging across subjects. See make_event_bins for
%                bin definition types. ([])
%   dist       - option for distributing jobs when calculating
%                event_bins. See apply_to_pat for details. (0)
%   save_mat   - if true, the new pattern will be saved to disk. (true)
%   res_dir    - directory to save the new pattern. Default is subj(1)'s
%                pattern's res_dir.

% input checks
if ~exist('pat_name', 'var')
  error('You must specify the name of the patterns you want to concatenate.')
elseif ~exist('subj', 'var')
  error('You must pass a subj structure.')
elseif ~isstruct(subj)
  error('subj must be a structure.')
end

% get info from the first subject
subj_pat = getobj(subj(1), 'pat', pat_name);
defaults.event_bins = [];
defaults.dist = 0;
defaults.save_mat = true;
defaults.res_dir = get_pat_dir(subj_pat, 'patterns');
params = propval(varargin, defaults);

source = 'ga';
if ~isempty(params.event_bins)
  subj = apply_to_pat(subj, pat_name, @bin_pattern, ...
                      {'eventbins', params.event_bins, ...
                      'save_mats', false}, params.dist);
  subj_pat = getobj(subj(1), 'pat', pat_name);
  subj_pat.dim.ev.modified = true;
end

% initialize the new pattern
pat_file = fullfile(params.res_dir, objfilename('pattern', pat_name, source));
pat = init_pat(pat_name, pat_file, source, subj_pat.params, ...
               subj_pat.dim);

% load and concatenate all subject patterns
fprintf('calculating grand average for pattern "%s"...', pat_name)
pattern = getvarallsubj(subj, {'pat', pat_name}, 'pattern', 5);

% average across subjects
pattern = nanmean(pattern, 5);

% if events were binned, save them in a new file
if pat.dim.ev.modified
  pat.dim.ev.file = fullfile(params.res_dir, ...
                             objfilename('events', pat.name, pat.source));
end

% save the new pattern
if params.save_mat
  pat = set_mat(pat, pattern, 'hd');
  
  if pat.dim.ev.modified
    pat.dim.ev = move_obj_to_hd(pat.dim.ev);
  end
  
  fprintf('saved.\n')
else
  pat = set_mat(pat, pattern, 'ws');
  pat.modified = true;
  fprintf('done.\n')
end

