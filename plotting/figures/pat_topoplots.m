function eeg = pat_topoplots(eeg, params, resDir, figname)
%
%PAT_PLOTS - manages event-related potential/power figures, plus
%topo plots of both voltage and power
%
% FUNCTION: eeg = pat_topoplots(eeg, params, resDir, figname)
%
% INPUT: eeg - struct created by init_iEEG or init_scalp
%        params - required fields: patname (specifies the name of
%                 which pattern in the eeg struct to use)
%
%                 optional fields: eventFilter (specify subset of
%                 events to use), masks (cell array containing
%                 names of masks to apply to pattern), subjects
%                 (cell array of ids of subjects to include) erp (set to
%                 1 to make an event-related plot for each
%                 channel), topo (set to 1 to make a headplot for
%                 each event type, time bin and frequency), diff
%                 (set to 1 to plot difference of eventypes)
%                 across_subj (set to 1 to plot patterns saved in eeg.pat)
%
%        resDir - plots saved in resDir/figs
%
% OUTPUT: new eeg struct with filenames of all figures created
% saved in pat.figs
%

params = structDefaults(params, 'diff', 0);

if ~exist(fullfile(resDir, 'figs'), 'dir')
  mkdir(fullfile(resDir, 'figs'))
end

clf reset

pattern = loadPat(pat, params);

fig.name = figname;
fig.type = 'topo';
fig.file = {};
fig.params = params;

if params.diff & size(pattern,1)==2
  pattern = pattern(2,:,:,:)-pattern(1,:,:,:);
end

for e=1:size(pattern,1)
  for t=1:size(pattern,3)
    for f=1:size(pattern,4)

      h = topoplot(squeeze(pattern(e,:,t,f)), params);
      for v=1:length(h)
        fig.file{e,v,t,f} = fullfile(resDir, 'figs', [params.patname '_topo_' id 'e' num2str(e) 'v' num2str(v) 't' num2str(t) 'f' num2str(f) '.eps']);
        print(h(v), '-depsc', '-r100', fig.file{e,v,t,f});
      end
    end
  end

end

pat = setobj(pat, 'fig', fig);
