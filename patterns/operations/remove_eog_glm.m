function subj = remove_eog_glm(subj, stat_name, pat_name, H_pat_name, ...
                               V_pat_name, varargin)
%REMOVE_EOG_GLM   Fit EOG data to a pattern using a GLM.
%
%  subj = remove_eog_glm(subj, stat_name, pat_name, H_pat_name, V_pat_name, ...)
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
%  H_pat_name:  name of a pattern containing measurements of horizontal
%               eye movements.
%
%  V_pat_name:  name of a pattern containing measurements of horizontal
%               eye movements.
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

% options
defaults.distr = 'normal';
defaults.link = '';
defaults.glm_inputs = {};
defaults.overwrite = true;
defaults.res_dir = get_pat_dir(pat, 'stats');
params = propval(varargin, defaults);

%get the pat objects
pat = getobj(subj, 'pat', pat_name);
H_eog_pat = getobj(subj, 'pat', H_pat_name);
V_eog_pat = getobj(subj, 'pat', V_pat_name);


warnings = zeros(length(subj.chan));
%else
warning('off', 'all');


%get the pattern matrices 
pattern = get_mat(pat);
H_eog_pattern = get_mat(H_eog_pat);
V_eog_pattern = get_mat(V_eog_pat);

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
beta_num = (2*num_sessions);

%create seperate eog measures for each session
for sess = 1:num_sessions
  H_eog{sess} = H_eog_pattern.*(H_session_pattern == sessions(sess));
  V_eog{sess} = V_eog_pattern.*(V_session_pattern == sessions(sess));

  %pre-allocate memory for the statistics patterns
  p.h{sess} = NaN(length(subj.chan),1);
  p.v{sess} = NaN(length(subj.chan),1);
end

tstat = p;
beta = p;

%clear space in memory
clear H_eog_pattern
clear V_eog_pattern
clear H_session_pattern
clear V_session_pattern

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
  for r = 1:2:(beta_num-1)
    %reshape the pattern
    counter = counter + 1;
    H_eog{counter} = permute(H_eog{counter}, [1 3 2]);
    H_eog{counter} = reshape(H_eog{counter}, size(H_eog{counter}, ...
                                                  1)*size(H_eog{counter},2),1);
    V_eog{counter} = permute(V_eog{counter}, [1 3 2]);
    V_eog{counter} = reshape(V_eog{counter}, size(V_eog{counter}, ...
                                                  1)*size(V_eog{counter},2),1);
    x(:,(r)) = [H_eog{counter}];
    x(:,(r+1)) = [V_eog{counter}];
  end
  
  %we then call glmfit
  %b contains the slope and x-intercept for the line of best fit
  % stats contains the p-values and t-stats for the regressor
  % coefficients
  if ~isempty(params.link)
    params.glm_inputs = {params.glm_inputs{:}, 'link', params.link};
  end
  [b, dev, stats] = glmfit(x, ev_vec, params.distr, params.glm_inputs{:});
  
  warn = lastwarn;
  if length(warn) > 0
    warnings(c) = 1;
  end
  
  
  resid(:,c) = stats.resid;
  yhat(:,c) = glmval(b,x,link_func);
  
  % below we try and fix a problem with zscoring when #observations is
  % very low, which causes the standard dev to be close to 0 (or 0)
  % and results in zscore values that are falsely high
  %if sum(~isnan(resid(:,c)))<100
  %  resid(:,c) = Nan;
  %end
  
  counter = 0;
  
  for r = 2:2:(beta_num)
    counter = counter + 1;
    p.h{counter}(c) = stats.p(r);
    tstat.h{counter}(c) = stats.t(r);
    p.v{counter}(c) = stats.p(r+1);
    tstat.v{counter}(c) = stats.t(r+1);
    beta.h{counter}(c) = stats.beta(r);
    beta.v{counter}(c) = stats.beta(r+1);
  end
end

%something is wrong with the p value of the regressor
resid = cont2seg(resid, pat_size);
yhat = cont2seg(yhat, pat_size);

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
save(stat.file, 'yhat', '-append');
%
save(stat.file, 'beta', '-append');
%


stat.warnings = sum(warnings(:));
subj = setobj(subj, 'pat', pat_name, 'stat', stat);

