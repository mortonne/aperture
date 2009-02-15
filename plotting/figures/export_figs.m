function fig_files = export_figs(subj,pat_name,fig_name,dim)

fig_files = {};
for this_subj=subj
  pat = getobj(this_subj, 'pat', pat_name);
  fig = getobj(pat, 'fig', fig_name);
  fig_files = cat(dim, fig_files, fig.file);
end
