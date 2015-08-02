function intrusions = create_intrusions(rec_itemnos, pres_itemnos, ...
                                        subjects, sessions, trials, ...
                                        pres_subj, pres_sess, pres_trial)
%CREATE_INTRUSIONS   Create a standard intrusions matrix.
%
% USAGE:
% create_intrusions(rec_itemnos, pres_itemnos, subjects, sesssions)
%
% create_intrusions(rec_itemnos, pres_itemnos, subjects, sessions, trials)
%
% create_intrusions(rec_itemnos, pres_itemnos, subjects, sessions, trials,
%                   pres_subj, pres_sess, pres_trial)
%
% INPUTS:
% rec_itemnos: a matrix whose elements are INDICES of recalled
% items. The rows of this matrix should represent recalls
% made by a single subject on a single trial.
%
% pres_itemnos: a matrix whose elements are INDICES of PRESENTED
% items. The rows of this matrix should represent the index of words
% shown to subjects during a trial.
%
% subjects: a column vector which indexes the rows of 
% rec_itemnos with a subject number (or other identifier). 
% That is, the recall trials of subject S should be located in
% rec_itemnos(find(subjects==S), :)
%
% sessions: a column vector which indexes the rows of
% rec_itemnos with a session number (or other identifier). 
% That is, the recall trials of subject S and session R should be
% located in rec_itemnos(find(subjects==S & sessions==R), :)
% 
% trials: a column vector which indexes the rows of
% rec_itemnos with a trial number (or other identifier).
% This trial number is used to determine which items have been
% previously presented within sessions.  If no trials vector is
% given, trials are assumed to be presented in the order given by
% rec_itemnos, as indicated by subjects and sessions.
%
% OPTIONAL INPUTS:
% pres_subj: a column vector which indexes the rows of
% pres_itemnos with a subject number (or other identifier).
% That is, the presented trials of subject S should be located in
% pres_itemnos(find(pres_subj==S), :)
%
% pres_sess: a column vector which indexes the rows of
% pres_itemnos with a session number (or other identifier).
% That is, the presented trials of subject S and session R should
% be located in pres_itemnos(find(subjects==S & sessions==R), :)
%
% pres_trials: a column vector which indexes the rows of
% pres_itemnos with a trial number (or other identifier).
% This trial number is used to determine which items have been
% previously presented within sessions.  If no pres_trial vector is
% given, trials are assumed to be presented in the order given by
% pres_itemnos, as indicated by pres_subj and pres_sess.
%

% sanity checks, and default behavior
if ~exist('rec_itemnos', 'var')
  error('You must pass a rec_itemnos matrix.')
elseif ~exist('pres_itemnos', 'var')
  error('You must pass a pres_itemnos matrix.')
elseif ~exist('subjects', 'var')
  error('You must pass a subjects vector.')
elseif ~exist('sessions', 'var')
  error('You must pass a sessions vector.')
elseif size(rec_itemnos, 1) ~= length(subjects)
  error('rec_itemnos matrix must have the same number of rows as subjects.')
elseif length(sessions) ~= length(subjects)
  error('sessions vector must have same length as subjects.')
end

if ~exist('trials','var')
  trials = default_trials(subjects, sessions);
elseif length(trials) ~= length(subjects)
  error('trials vector must have the same length as subjects.')
end

if ~exist('pres_subj', 'var')
  % pres info is same as rec info if not explicitly passed in
  pres_subj = subjects;
  pres_sess = sessions;
  pres_trial = trials;
  if size(pres_itemnos,1) ~= length(subjects)
    error('pres_itemnos matrix must have the same number of rows as subjects.')
  end
elseif ~exist('pres_sess', 'var')
  error('If you pass in pres_subj vector, you must pass an accompanying pres_sess vector.')
elseif size(pres_itemnos,1) ~= length(pres_subj)
  error('pres_itemnos matrix must have the same number of rows as pres_subj.')
end

if ~exist('pres_trial','var')
  pres_trial = default_trials(pres_subj, pres_sess);
elseif length(pres_trial) ~= length(pres_subj)
  error('pres_trial vector must have the same length as pres_subj.')
end


% create intrusions matrix
intrusions = zeros(size(rec_itemnos));

for tr = 1:size(rec_itemnos,1)
  this_subj = subjects(tr);
  this_sess = sessions(tr);
  this_trial = trials(tr);
  
  % this list's presented items
  list_items = pres_itemnos(pres_subj==this_subj & ...
                            pres_sess==this_sess & ...
                            pres_trial==this_trial, ...
                            :);
  % previous list items
  previous_items = pres_itemnos(pres_subj==this_subj & ...
                                pres_sess==this_sess & ...
                                pres_trial<this_trial, ...
                                :);
  previous_items = unique(previous_items(:))';
  
  for op = 1:size(rec_itemnos,2)
    this_itemno = rec_itemnos(tr,op);
    
    % check for valid recall
    if ~isnan(this_itemno) & this_itemno~=0
      % check for correct recall
      if ~any(list_items==this_itemno)
        
        % mask to single out this session's trials
        prev_mask = pres_subj==this_subj & ...
                    pres_sess==this_sess & ...
                    pres_trial<this_trial;
        
        % look for previous item presentations
        prev_found = find(any(pres_itemnos==this_itemno,2) & ...
                              prev_mask);
        
        if isempty(prev_found)
          % not previously presented, xli
          intrusions(tr, op) = -1;
        elseif length(prev_found) > 1
          % presented more than once, error
          error('Item %d was presented more than once in Subj %d sess %d.', ...
                 this_itemno, this_subj, this_sess);
        else
          % found in one previous list, pli
          intrusions(tr, op) = this_trial - pres_trial(prev_found);
        end
                
      end
    end      
    
    
  end
end



function trials = default_trials(subjects, sessions)
%DEFAULT_TRIALS
% returns a trials vector assuming trials are in order by subject
% and session

[sess,vals] = make_index(subjects, sessions);

uniq_sess = unique(sess);

trials = NaN(length(sess),1);
for ind = 1:length(unique(sess))
  this_ind = uniq_sess(ind);
  
  num_trials = sum(sess==this_ind);
  
  trials(sess==this_ind) = [1:num_trials]';
end
