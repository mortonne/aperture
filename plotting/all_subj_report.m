function all_subj_report(exp, patname, figname)

pat = getobj(exp.subj(1), 'pat', patname);
fig = getobj(pat, 'fig', figname);
title = fig.title;

for s=1:length(exp.subj)
  pat = getobj(exp.subj(s), 'pat', patname);
  fig(s) = getobj(pat, 'fig', figname);
  fig(s).title = exp.subj(s).id;
end

chan = pat.dim.chan;
reportfile = fullfile(fileparts(fileparts(pat.file)), [figname '_report']);
report_by_channel(chan, fig, reportfile, title);
