function exp = cat_all_subj_events(exp, ev_name, res_dir)
%CAT_ALL_SUBJ_EVENTS   Concatenate events from all subjects.
%
%  exp = cat_all_subj_events(exp, ev_name, res_dir)
%
%  INPUTS:
%      exp:  an experiment object.
%
%  ev_name:  name of the experiment objects to concatenate.
%
%  res_dir:  directory where the concatenated events structure will be
%            saved.  Default is the directory where the first subject's
%            events are saved.
%
%  OUTPUTS:
%      exp:  experiment object with an added ev object named ev_name
%            containing the concatenated events.

% input checks
if ~exist('exp', 'var')
  error('You must pass an experiment object.')
elseif ~exist('ev_name', 'var')
  error('You must specify the name of the events to concatenate.')
end

% export all of the ev objects
evs = getobjallsubj(exp.subj, {'ev', ev_name});

% concatenate
if exist('res_dir', 'var')
  ev = cat_events(evs, ev_name, exp.experiment, res_dir);
else
  ev = cat_events(evs, ev_name, exp.experiment);
end

% add the new ev object to the experiment object
exp = setobj(exp, 'ev', ev);
