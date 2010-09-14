function subj = remove_eog_glm(subj, pat_name, new_pat_name, varargin)
%REMOVE_EOG_GLM   Fit EOG data to a pattern using a GLM.
%
%  subj = remove_eog_glm(subj, pat_name, new_pat_name, ...)
%  
%  INPUTS:
%        subj:  a subject structure.
%
%    pat_name:  name of the pattern object to fit. Each channel will be
%               fit separately to the horizontal and vertical EOG
%               regressors.
%
%  OUTPUTS:
%        subj:  the subject structure with the GLM stat object added.
%
%  PARAMS:
%  These options may be specified using parameter, value pairs or by
%  passing a structure. Defaults are shown in parentheses.
%   distr      - distribution to use for the GLM. ('normal')
%   link       - link function to use in place of the canonical link;
%                see glmfit. ('')
%   glm_inputs - cell array of additional inputs to glmfit. ({})
%   overwrite  - if true, if the stat file already exists, it will be
%                overwritten. (true)
%   res_dir    - directory in which to save the GLM results. Default is
%                the pattern's stats directory.
%   blink_thresh - threshold in microvolts for detecting blinks. If
%                optimize_thresh is true, this will not be used. (100)
%   blink_buffer - buffer to make around the start of each detected
%                blink. ([-150 500])
%   optimize_thresh - if true, use dprime optimization to find the
%                best value for blink thresholding - must have
%                trackball pattern on subj structure (false)
%   trackball_pat_name - name of your trackball pattern
%   veog_chans - array cell array of arrays of channel numbers of VEOG
%                channels. ({[8 126] [25 127]})
%   heog_chans - array cell array of arrays of channel numbers of HEOG
%                channels. ([1 32])
%   eog_max_nan - fraction of NaNs allowed in a given EOG channel. (0.4)

pat = getobj(subj, 'pat', pat_name);

% options
defaults.distr = 'normal';
defaults.link = '';
defaults.glm_inputs = {};
defaults.overwrite = true;
defaults.res_dir = get_pat_dir(pat, 'stats');
defaults.blink_thresh = 100;
defaults.blink_buffer = [-150 500];
defaults.optimize_thresh = false;
defaults.trackball_pat_name = '';
defaults.veog_chans = {[8 126] [25 127]};
defaults.heog_chans = [1 32];
defaults.eog_max_nan = 0.4;
params = propval(varargin, defaults);

if ~iscell(params.veog_chans)
  params.veog_chans = {params.veog_chans};
end
if ~iscell(params.heog_chans)
  params.heog_chans = {params.heog_chans};
end

pat = move_obj_to_workspace(pat);

% find the best EOG patterns
veog_pat = get_best_eog(pat, params.veog_chans, 'VEOG', params.eog_max_nan);
veog_chans = get_dim_vals(veog_pat.dim, 'chan');
heog_pat = get_best_eog(pat, params.heog_chans, 'HEOG', params.eog_max_nan);

% optimize the blink threshold based on trackball data
if params.optimize_thresh
  if isempty(params.trackball_pat_name)
    error('optimize_thresh requires trackball_pat_name.')
  end
  trackball_pat = getobj(subj, 'pat', params.trackball_pat_name);
  p = [];
  p.veog_chans = veog_chans;
  params.blink_thresh = optimize_blink_detector(trackball_pat, p);
  clear trackball_pat
end

% get a mask of samples containing blinks
pre = sum(abs(params.blink_buffer)) + 500;
post = abs(params.blink_buffer(1));
eog_params = pat.params;
eog_params.chanFilter = veog_chans;
eog_params.offsetMS = pat.params.offsetMS - pre;
eog_params.durationMS = pat.params.durationMS + pre + post;
eog_params.relativeMS = [];
eog_params.filttype = 'bandpass';
eog_params.filtfreq = [.5 30];
eog_params.filtorder = 4;
eog_params.bufferMS = 1000;
eog_params.verbose = false;
eog_params.overwrite = true;
eog_pat_name = 'eog';
res_dir = fullfile(fileparts(get_pat_dir(pat)), eog_pat_name);
temp = create_voltage_pattern(subj, eog_pat_name, eog_params, res_dir);
eog_pat = getobj(temp, 'pat', eog_pat_name);
eog_pattern = get_mat(eog_pat);

blink_params = [];
blink_params.reject_full = false;
blink_params.buffer = params.blink_buffer;
blink_params.debug_plots = true;
blink_params.chans = [1 2];
blink_params.samplerate = get_pat_samplerate(eog_pat);
blink_mask = reject_blinks(eog_pattern, params.blink_thresh, blink_params);

% remove the buffer
filt_str = sprintf('%.4f <= avg & avg < %.4f', pat.params.offsetMS, ...
                   pat.params.offsetMS + pat.params.durationMS);
[temp, inds] = patFilt(eog_pat, 'timeFilter', filt_str);
blink_mask = blink_mask(:,1,inds{3});

clear temp eog_pat eog_pattern

% get the session vector
events = get_dim(pat.dim, 'ev');
session = [events.session]';
clear events

% load EOG channels
v_pattern = get_mat(veog_pat);
h_pattern = get_mat(heog_pat);

pattern = get_mat(pat);
pat.mat = [];
[n_events, n_chans, n_samps] = size(pattern);
chan_labels = get_dim_labels(pat.dim, 'chan');
n_reg = 4;
resid = NaN(size(pattern), class(pattern));
sessions = unique(session);
fprintf('Running GLM...\n')
for i = 1:length(sessions)
  fprintf('Session %d: ', sessions(i))
  sess_mask = session == sessions(i);
  n_events = nnz(sess_mask);
  
  % column vectors with EOG data
  veog = seg2cont(v_pattern(sess_mask,:,:));
  heog = seg2cont(h_pattern(sess_mask,:,:));
  blink = seg2cont(blink_mask(sess_mask,:,:));
  
  X = zeros(n_events * n_samps, n_reg);
  X(:,1) = veog .* ~blink;
  X(:,2) = heog .* ~blink;
  X(:,3) = veog .* blink;
  X(:,4) = heog .* blink;
  
  for j = 1:n_chans
    fprintf('%s ', chan_labels{j})
    data = seg2cont(pattern(sess_mask,j,:));
    [b, dev, stats] = glmfit(X, data, params.distr, params.glm_inputs{:});
    resid(sess_mask,j,:) = cont2seg(stats.resid, [n_events 1 n_samps]);
  end
  fprintf('\n')
end

% create a new pattern from the residuals
pat.name = new_pat_name;
pat_dir = fullfile(fileparts(get_pat_dir(pat)), new_pat_name, 'patterns');
if ~exist(pat_dir, 'dir')
  mkdir(pat_dir)
end
pat.file = fullfile(pat_dir, objfilename('pattern', new_pat_name, pat.source));
pat = set_mat(pat, resid, 'hd');

subj = setobj(subj, 'pat', pat);


function eog_pat = get_best_eog(pat, chan_pairs, eog_type, max_nan)
%GET_BEST_EOG   Search over EOG channels to find the most artifact-free.

n_chan_pairs = length(chan_pairs);
bad_samp = NaN(1, n_chan_pairs);
eog_pats = cell(1, n_chan_pairs);
eog_pat_name = sprintf('%s_%s', pat.name, eog_type);
for i=1:n_chan_pairs
  chans = chan_pairs{i};
  
  % get the difference between these channels
  eog_pat = diff_pattern(pat, 'chans', {chans}, ...
                         'chanlabels', {eog_type}, ...
                         'save_as', eog_pat_name, ...
                         'save_mats', false);
  eog_pattern = get_mat(eog_pat);
  
  % check the fraction of NaNs in the pattern
  bad_samp(i) = nnz(isnan(eog_pattern)) / numel(eog_pattern);
  eog_pats{i} = eog_pat;
end

% determine if any EOG channels are usable
if ~any(bad_samp < max_nan)
  error('All %s channel pairs have greater then %%%.2f bad samples', ...
        eog_type, max_nan * 100)
end

% get the best, move it to disk
[y, best_ind] = min(bad_samp);
eog_pat = eog_pats{best_ind};
eog_pat = move_obj_to_hd(eog_pat);

