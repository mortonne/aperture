function subj = remove_eog_glm(subj, stat_name, pat_name, varargin)
%REMOVE_EOG_GLM   Fit EOG data to a pattern using a GLM.
%
%  subj = remove_eog_glm(subj, stat_name, pat_name, ...)
%  
%  INPUTS:
%        subj:  a subject structure.
%
%   stat_name:  name of the stat object to create that will hold the
%               results of the GLM.
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
%   find_best_thresh - if true, use dprime optimization to find the
%                best value for blink thresholding - must have
%                trackball pattern on subj structure (false)
%   trackball_pat_name - name of your trackball pattern
%
%
%
%
%
%


%create the eog patterns
p = [];
V_pat_name1 = ['vEOG1_' pat_name];
p.save_as = V_pat_name;
chans1 = [8 126];
p.chans = {[8 126]};
p.overwrite = true;
subj = apply_to_pat(subj, pat_name, @diff_pattern, {p}, 1)

p = [];
V_pat_name2 = ['vEOG2_' pat_name];
p.save_as = V_pat_name;
p.chans = {[25 127]};
chans1 = [25 127];
p.overwrite = true;
subj = apply_to_pat(subj, pat_name, @diff_pattern, {p}, 1)

V_eog_pat1 = getobj(subj, 'pat', V_pat_name1);
V_eog_pat2 = getobj(subj, 'pat', V_pat_name2);
V_eog_pattern1 = get_mat(V_eog_pat1);
V_eog_pattern2 = get_mat(V_eog_pat2);
%choose the vEOG pair that has fewer NaNs
%this should act as bootleg bad eog chan detection
if mean(mean(isnan(V_eog_pattern1))) >= ...
      mean(mean(isnan(V_eog_pattern2)))
  %set name to best Veog pattern
  V_pat_name = V_pat_name1;
  %set chans to be used in blink detection
  chans = chans1;
else
  V_pat_name = V_pat_name2;  
  chans = chans2;
end

%check to make sure both pairs of vEOG chans aren't bad
if mean(mean(isnan(V_eog_pattern1)))>.4 && ...
      mean(mean(isnan(V_eog_pattern2)))>.4
  %we could add a session-wise rejection here to save the data
  %for now, just print error
  error('Both verticle EOG pairs bad.')
end

%clear space in memory
clear V_pat_name1
clear V_pat_name2
clear V_eog_pat1
clear V_eog_pat2
clear V_eog_pattern1
clear_V_eog_pattern2

%make H_eog pattern
H_pat_name = ['hEOG_' pat_name];
p = [];
p.save_as = H_pat_name;
p.overwrite = true;
p.chans = [1 32];
subj = apply_to_pat(subj, pat_name, @diff_pattern, {p}, 1)

%get the pat objects
pat = getobj(subj, 'pat', pat_name);
H_eog_pat = getobj(subj, 'pat', H_pat_name);
V_eog_pat = getobj(subj, 'pat', V_pat_name);

% options
defaults.distr = 'normal';
defaults.link = '';
defaults.glm_inputs = {};
defaults.overwrite = true; 
defaults.res_dir = get_pat_dir(pat, 'stats');
defaults.find_best_thresh = false; 
defaults.trackball_pat_name = '';
params = propval(varargin, defaults);


warnings = zeros(length(subj.chan));
%else
warning('off', 'all');

best_thresh = [100];
%if you want to use dynamic thresh search:
if params.find_best_thresh
  if isempty(trackball_pat_name)
    error('find_best_thresh requires trackball_pat_name.')
  end
  trackball_pat = getobj(subj, 'pat', trackball_pat_name)
  p = [];
  p.veog_chans = chans;
  [best_thresh, blink_thresh] = optimize_blink_detector(trackball_pat, ...
                                                    p)
  clear blink_thresh
  clear trackball_pat
  pat.best_thresh = best_thresh;
end
%
%

if ~isempty(pat.best_thresh)
  best_thresh = pat.best_thresh;
end
%


%get the pattern matrices 
pattern = get_mat(pat);
H_eog_pattern = get_mat(H_eog_pat);
V_eog_pattern = get_mat(V_eog_pat);

%check to make sure H_eog channels aren't bad
if mean(mean(isnan(H_eog_pattern)))>.1
  error('Horizontal EOG pair probably bad.')
end


%run blink detection
thresh = [100];
if ~isempty(best_thresh)
  thresh = best_thresh;
end
blink_params = [];
blink_params.reject_full = false;
blink_params.buffer = true;
%this was set above based on eog pair with least nans
blink_params.chans = chans;
blink_mask = reject_blinks(pattern, thresh, blink_params);
blink_mask = blink_mask(:,1,:);

%add sanity checks about the pattern

%get the events structure
events = get_dim(pat.dim, 'ev');
H_events = get_dim(H_eog_pat.dim, 'ev');
V_events = get_dim(V_eog_pat.dim, 'ev');

%add sanity checks about the events

%create room in memory
clear H_eog_pat
clear V_eog_pat

%get the task matrix of the events structure
%vectorize it, and then transpose it
%task_vec = single([events.task]');
H_session_vec = single([H_events.session]');
V_session_vec = single([V_events.session]');

%create room in memory
clear events
clear H_events
clear V_events

%find the time dimension
time_size = size(pattern,3);

%create a pattern for the session info
H_session_pattern = repmat(H_session_vec, [1, 1, time_size]);
V_session_pattern = repmat(V_session_vec, [1, 1, time_size]);


%add sanity check comparing session_pattern to eog_pattern

%to be developed:
%need to add check if stat object already exists
%if stat obj exists
%stat = getobj(pat, 'stat', stat_name);
%else
stat_file = fullfile(params.res_dir, ...
                     objfilename('stat', stat_name, subj.id));

% check the output file
if ~params.overwrite && exist(stat_file, 'file')
  return
end

stat = init_stat(stat_name, stat_file, subj.id);
%end

     
%sanity check
if isequal(unique(H_session_vec), unique(V_session_vec))
  %print warning message and perhaps throw error
end

%count the number of sessions
num_sessions = length(unique([H_session_vec]));
sessions = unique([H_session_vec]);

%define number of regressors
beta_num = (5*num_sessions);

%create seperate eog measures for each session
for sess = 1:num_sessions
  H_Beog{sess} = H_eog_pattern.*(H_session_pattern == sessions(sess)).*blink_mask;
  V_Beog{sess} = V_eog_pattern.*(V_session_pattern == sessions(sess)).*blink_mask;
  H_eog{sess} = H_eog_pattern.*(H_session_pattern == sessions(sess)).*~blink_mask;
  V_eog{sess} = V_eog_pattern.*(V_session_pattern == sessions(sess)).*~blink_mask;
  constant{sess} = (V_session_pattern == sessions(sess));
  
  %pre-allocate memory for the statistics patterns
  p.hb{sess} = NaN(length(subj.chan),1);
  p.vb{sess} = NaN(length(subj.chan),1);
  p.h{sess} = NaN(length(subj.chan),1);
  p.v{sess} = NaN(length(subj.chan),1);
  
  
end

tstat = p; 
beta = p;

%clear space in memory
clear H_eog_pattern
clear V_eog_pattern
clear int_eog_pattern
clear H_session_pattern
clear V_session_pattern
clear blink_mask

%reshape the pattern vector
[pattern, pat_size] = seg2cont(pattern, size(pattern));

resid = NaN(size(pattern),'single');
yhat = NaN(size(pattern),'single');

%pre-allocate memory for x
x = [zeros(pat_size(1)*pat_size(3),beta_num)];

%this iterates over channels and timepoints
%at each channel/timepoint, 
for c = 1:length(subj.chan)
  lastwarn('');
  %to get the event-wise voltage vector, we use the channel and
  %time indices 
  ev_vec = pattern(:,c);   
  
  %we then define x for glm fit, with each regressor as its own
  %column
  %HOW WILL THIS WORK
  counter = 0;
  for r = 1:5:(beta_num-1)
    %reshape the pattern
    counter = counter + 1;
    H_Beog{counter} = permute(H_Beog{counter}, [1 3 2]);
    H_Beog{counter} = reshape(H_Beog{counter}, size(H_Beog{counter}, ...
                                                  1)*size(H_Beog{counter},2),1);
    V_Beog{counter} = permute(V_Beog{counter}, [1 3 2]);
    V_Beog{counter} = reshape(V_Beog{counter}, size(V_Beog{counter}, ...
                                                  1)*size(V_Beog{counter},2),1);
    H_eog{counter} = permute(H_eog{counter}, [1 3 2]);
    H_eog{counter} = reshape(H_eog{counter}, size(H_eog{counter}, ...
                                                  1)*size(H_eog{counter},2),1);
    V_eog{counter} = permute(V_eog{counter}, [1 3 2]);
    V_eog{counter} = reshape(V_eog{counter}, size(V_eog{counter}, ...
                                                  1)*size(V_eog{counter},2),1);
    
    constant{counter} = permute(constant{counter}, [1 3 2]);
    constant{counter} = reshape(constant{counter}, size(constant{counter}, ...
                                                  1)*size(constant{counter},2),1);
    
    
    x(:,(r)) = [H_Beog{counter}];
    x(:,(r+1)) = [V_Beog{counter}];
    x(:,(r+2)) = [H_eog{counter}];
    x(:,(r+3)) = [V_eog{counter}];
    x(:,(r+4)) = [constant{counter}];
    
  end
  
  %we then call glmfit
  %b contains the slope and x-intercept for the line of best fit
  % stats contains the p-values and t-stats for the regressor
  % coefficients
  if ~isempty(params.link)
    params.glm_inputs = {params.glm_inputs{:}, 'link', params.link, ...
                        'constant', 'off'};
  end
   
  [b, dev, stats] = glmfit(x, ev_vec, params.distr, params.glm_inputs{:});
  
  warn = lastwarn;
  if length(warn) > 0
    warnings(c) = 1;
  end
  
  
  resid(:,c) = stats.resid;
%  yhat(:,c) = glmval(b,x,'link',params.link,'constant','off');
  
  % below we try and fix a problem with zscoring when #observations is
  % very low, which causes the standard dev to be close to 0 (or 0)
  % and results in zscore values that are falsely high
  %if sum(~isnan(resid(:,c)))<100
  %  resid(:,c) = Nan;
  %end
  
  counter = 0;
  
  for r = 1:5:(beta_num)
    counter = counter + 1;
    p.hb{counter}(c) = stats.p(r);
    tstat.hb{counter}(c) = stats.t(r);
    p.vb{counter}(c) = stats.p(r+1);
    tstat.vb{counter}(c) = stats.t(r+1);
    p.h{counter}(c) = stats.p(r+2);
    tstat.h{counter}(c) = stats.t(r+2);
    p.v{counter}(c) = stats.p(r+3);
    tstat.v{counter}(c) = stats.t(r+3);
 
    %   p.int{counter}(c) = stats.p(r+2);
 %   tstat.int{counter}(c) = stats.t(r+2);
    
    beta.hb{counter}(c) = stats.beta(r);
    beta.vb{counter}(c) = stats.beta(r+1);
    beta.h{counter}(c) = stats.beta(r+2);
    beta.v{counter}(c) = stats.beta(r+3);
  %  beta.int{counter}(c) = stats.beta(r+2);
  end
end

%something is wrong with the p value of the regressor
resid = cont2seg(resid, pat_size);
%yhat = cont2seg(yhat, pat_size);

%p and tstat are no longer the size of the pattern
%so this will break later functions that graph them...

% if the stat object doesn't already exist
save(stat.file, 'p');
%else
%save(stat.file, p, '-append');
%end
save(stat.file, 'tstat', '-append');
%
save(stat.file, 'resid', '-append');
%
%save(stat.file, 'yhat', '-append');
%
save(stat.file, 'beta', '-append');
%


stat.warnings = sum(warnings(:));
subj = setobj(subj, 'pat', pat_name, 'stat', stat);






