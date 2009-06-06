function exp = cat_all_subj_events(exp,ev_name,res_dir)
%CAT_ALL_SUBJ_EVENTS   Concatenate events from all subjects.
%
%  exp = cat_all_subj_events(exp,ev_name,res_dir)

evs = getobjallsubj(exp.subj, {'ev', ev_name});
if ~exist('res_dir','var')
  res_dir = get_ev_dir(evs(1), 'events');
end

ev = cat_events(evs, ev_name, res_dir, exp.experiment);
exp = setobj(exp, 'ev', ev);
