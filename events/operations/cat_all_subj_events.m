function exp = cat_all_subj_events(exp,ev_name,res_dir)
%
%

evs = getobjallsubj(exp.subj, {'ev', ev_name});
ev = cat_events(evs, ev_name, res_dir, exp.experiment);
exp = setobj(exp, 'ev', ev);
