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
%   distr        - distribution to use for the GLM. ('normal')
%   link         - link function to use in place of the canonical link;
%                  see glmfit. ('')
%   glm_inputs   - cell array of additional inputs to glmfit. ({})
%   overwrite    - if true, if the stat file already exists, it will be
%                  overwritten. (true)
%   res_dir      - directory in which to save the GLM results. Default
%                  is the pattern's stats directory.
%   blink_thresh - threshold in microvolts for detecting blinks. If
%                  optimize_thresh is true, this will not be used. (100)
%   blink_buffer - buffer to make around the start of each detected
%                  blink. ([-150 500])
%   debug_plots  - if true, all events will be plotted with blinks
%                  marked for purposes of checking blink detection.
%                  (false)
%   optimize_thresh - if true, use dprime optimization to find the best
%                  value for blink thresholding - must have a trackball
%                  pattern. (false)
%   trackball_pat_name - name of a pattern with up, down, right, left,
%                  and blink events. ('')
%   veog_chans   - array cell array of arrays of channel numbers of VEOG
%                  channels. ({[8 126] [25 127]})
%   heog_chans   - array cell array of arrays of channel numbers of HEOG
%                  channels. ([1 32])
%   eog_max_nan  - fraction of NaNs allowed in a given channel. (0.4)
%   baselineMS   - baseline in ms ([start finish]) for applying baseline
%                  correction after eye movement correction. ([])

pat = getobj(subj, 'pat', pat_name);

% options
defaults.distr = 'normal';
defaults.link = '';
defaults.glm_inputs = {};
defaults.overwrite = true;
defaults.res_dir = get_pat_dir(pat, 'stats');
defaults.blink_thresh = 100;
defaults.blink_buffer = [-150 500];
defaults.debug_plots = false;
defaults.optimize_thresh = false;
defaults.trackball_pat_name = '';
defaults.search_thresh = 100:10:300;
defaults.veog_chans = {[8 126] [25 127]};
defaults.heog_chans = [1 32];
defaults.eog_max_nan = 0.4;
defaults.baselineMS = [];
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
  trackball_samplerate = get_pat_samplerate(trackball_pat);
  p = [];
  p.chans = veog_chans;
  p.search_thresh = params.search_thresh;
  params.blink_thresh = optimize_blink_detector(trackball_pat, p);
  clear trackball_pat
end

% create a VEOG pattern for detecting blinks
pre = sum(abs(params.blink_buffer)) + 500;
post = abs(params.blink_buffer(1));
eog_params = pat.params;
eog_params.chanFilter = veog_chans;
eog_params.offsetMS = pat.params.offsetMS - pre;
eog_params.durationMS = pat.params.durationMS + pre + post;
eog_params.relativeMS = [];
if exist('trackball_samplerate', 'var')
  eog_params.resampledRate = trackball_samplerate;
end
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

% get a mask marking blinks
blink_params = [];
blink_params.reject_full = false;
blink_params.buffer = params.blink_buffer;
blink_params.debug_plots = params.debug_plots;
blink_params.chans = [1 2];
blink_params.samplerate = get_pat_samplerate(eog_pat);
blink_mask = reject_blinks(eog_pattern, params.blink_thresh, blink_params);

% remove the buffer
samplerate = get_pat_samplerate(pat);
pat_time = get_dim_vals(pat.dim, 'time');
eog_time = get_dim_vals(eog_pat.dim, 'time');
finish = pat_time(end) + 1000 / samplerate;
filter = pat_time(1) <= eog_time & ...
         eog_time <= finish - eps(finish);
blink_mask = blink_mask(:,1,filter);

clear temp eog_pat eog_pattern

% get the session vector
events = get_dim(pat.dim, 'ev');
session = [events.session]';

% load EOG channels
v_pattern = get_mat(veog_pat);
h_pattern = get_mat(heog_pat);

pattern = get_mat(pat);
pat.mat = [];
[n_events, n_chans, n_samps] = size(pattern);

% resample the blink mask to match the pattern
if samplerate > blink_params.samplerate
  temp = false(n_events, 1, n_samps);
  for i = 1:size(blink_mask, 1)
    x = permute(blink_mask(i,1,:), [3 1 2]);
    y = resample(double(x), samplerate, blink_params.samplerate) > 0.1;
    temp(i,1,:) = y;
  end
  blink_mask = temp;
  clear temp
elseif blink_params.samplerate > samplerate
  % downsample
  error('downsampling blink mask not yet supported.')
end

% get a matrix with label for each unique sample
% get samplerate of the data (important because we need to know
% the exact sample for labeling)
samplerate_data = GetRateAndFormat(events(1));
samples = make_sample_matrix(events, pat_time(1), pat_time(end), ...
                             samplerate_data, samplerate);

% match the shape of the patterns
samples = permute(samples, [1 3 2]);
clear events

chan_labels = get_dim_labels(pat.dim, 'chan');
n_reg = 4;
resid = NaN(size(pattern), class(pattern));
sessions = unique(session);
fprintf('Running GLM...\n')
for i = 1:length(sessions)
  fprintf('Session %d: ', sessions(i))
  sess_mask = session == sessions(i);
  n_events = nnz(sess_mask);
  
  % find unique samples
  samp = seg2cont(samples(sess_mask,:,:));
  [first, uniq, repeated] = find_repeats(samp);
  n_repeats = length(repeated);

  % column vectors with EOG data
  veog = seg2cont(v_pattern(sess_mask,:,:));
  heog = seg2cont(h_pattern(sess_mask,:,:));
  blink = seg2cont(blink_mask(sess_mask,:,:));
  if n_repeats > 0
    veog = veog(uniq);
    heog = heog(uniq);
    blink = blink(uniq);
  end

  % make the design matrix
  X = zeros(length(veog), n_reg);
  X(:,1) = veog .* ~blink;
  X(:,2) = heog .* ~blink;
  X(:,3) = veog .* blink;
  X(:,4) = heog .* blink;
  
  for j = 1:n_chans
    fprintf('%s ', chan_labels{j})
    
    % vectorized data for this channel
    data = seg2cont(pattern(sess_mask,j,:));
    if n_repeats > 0
      data = data(uniq);
    end
    if all(isnan(data))
      continue
    end
    
    % model this channel using V + VB + H + HB + intercept
    [b, dev, stats] = glmfit(X, data, params.distr, params.glm_inputs{:});
    
    % get the residuals from the model
    if n_repeats == 0
      % no repeated samples to worry about
      resid(sess_mask,j,:) = cont2seg(stats.resid, [n_events n_samps 1]);
    else
      % fill in unique samples
      chan_resid = NaN(n_events * n_samps, 1);
      chan_resid(uniq) = stats.resid;
      
      % add to the new pattern
      resid(sess_mask,j,:) = cont2seg(chan_resid, [n_events n_samps 1]);
    end    
  end

  % expand repeats
  if n_repeats > 0
    sess_resid = resid(sess_mask,:,:);
    sess_samples = samples(sess_mask,:,:);
    resid(sess_mask,:,:) = replace_repeats(sess_samples, first, ...
                                           repeated, sess_resid);
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

% baseline correction
if ~isempty(params.baselineMS)
  pat = set_mat(pat, resid, 'ws');
  pat = baseline_pattern(pat, params.baselineMS, 'overwrite', true);
else
  pat = set_mat(pat, resid, 'hd');
end

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


function [first_repeat, uniq, repeated] = find_repeats(x)

  if size(x, 1) == 1
    x = x';
  end

  % unique vals of x
  ux = unique(x);

  % find the last index of each value
  [tf, loc1] = ismember(ux, x);

  % repeat, reversing x, so we get the first and last of each value
  [tf, loc2] = ismember(ux, flipud(x));
  loc2 = length(x) + 1 - loc2;

  % unique values are one with the same index either way
  uvals = loc1 == loc2;

  % first presentation of repeated values
  first_repeat = loc2(~uvals);

  % mask marking unique samples of x (including firsts)
  uniq = ismember(x, ux(uvals));
  uniq(first_repeat) = true;

  % list of repeated values
  repeated = ux(~uvals);

function y = replace_repeats(labels, first, repeated, x)
  %
  %  y = replace_repeats(labels, first, repeated, x)
  %
  %  INPUTS:
  %    labels:  [events X 1 X time] matrix with labels for each element of
  %             x.
  %
  %     first:  index of the first appearance of each repeated element.
  %
  %  repeated:  vector of repeated labels. 
  %
  %         x:  [events X channels X time] matrix.
  %
  %  OUTPUTS:
  %         y:  [events X channels X time] matrix with repeated values
  %             filled in.

  % find the first location of the repeated samples
  [e1,c1,t1,f1] = ind2sub(size(labels), first);

  y = x;
  n_repeats = length(repeated);
  n_chans = size(x, 2);
  for i = 1:n_repeats
    if mod(i, 1000) == 0
      fprintf('.')
    end
    
    % find where this sample was repeated
    reps = setdiff(find(labels == repeated(i)), first(i));
    [e,c,t,f] = ind2sub(size(labels), reps);
    for j = 1:n_chans
      for k = 1:length(e)
        y(e(k),j,t(k),f(k)) = x(e1(i),j,t1(i),f1(i));
      end
    end
  end
  
function y = seg2cont(x)
  y = x(:);
  
function y = cont2seg(x, siz)
  y = reshape(x, siz);
