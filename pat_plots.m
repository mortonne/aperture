function eeg = pat_plots(eeg, params, resDir)
%
%PAT_PLOTS - manages event-related potential/power figures, plus
%topo plots of both voltage and power
%
% FUNCTION: eeg = pat_plots(eeg, params, resDir)
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

if ~isfield(params, 'patname')
  error('You must specify which pattern to use')
end
if ~isfield(params, 'subjects')
  subjects = getStructField(eeg.subj, 'id');
end

params = structDefaults(params, 'erp', 1,  'topo', 1,  'diff', 0,  'across_subj', 0);

if ~exist(fullfile(resDir, 'figs'), 'dir')
  mkdir(fullfile(resDir, 'figs'))
end

clf reset

for i=1:length(subjects)
  s = find(inStruct(eeg.subj, 'strcmp(id, varargin{1})', subjects{i}));
  
  pat = getobj(eeg.subj(s), 'pat', params.patname);
  pattern = loadPat(pat.file);
  
  if params.diff & size(pattern,1)==2
    pattern = pattern(2,:,:,:)-pattern(1,:,:,:);
  end
  
  if params.erp
    for c=1:size(pattern,2)
      
      if isempty(pat.dim.freq)
	for e=1:size(pattern,1)
	  h = plot(getStructField(pat.dim.time, 'avg'), squeeze(pattern(e,c,:)), '-k');
	  xlabel('Time (ms)')
	  ylabel('Voltage')
	  hold on
	end
	hold off
	
	if sum(~isnan(get(h, 'YData')))>0
	  pat.figs.erp{c} = fullfile(resDir, 'figs', [eeg.subj(s).id '_' params.patname '_erp_' num2str(c) '.eps']);
	  print(gcf, '-depsc', pat.figs.erp{c});
	end
	
      else % plotting power values
	for e=1:size(pattern,1)
	  h = plot_pow(pattern(e,c,:,:), pat.dim);
	  
	  pat.figs.erp{e,c} = fullfile(resDir, 'figs', [eeg.subj(s).id '_' params.patname '_erp_' num2str(e) num2str(c) '.eps']);
	  print(gcf, '-depsc', pat.figs.erp{e,c});
	end
	
      end
      
    end % channels
  end % erps

  if params.topo
    for e=1:size(pattern,1)
      for t=1:size(pattern,3)
	for f=1:size(pattern,4)
	  
	  h = topoplot(pattern(e,:,t,f), params);
	  for v=1:length(h)
	    pat.figs.topo{e,v,t,f} = fullfile(resDir, 'figs', [eeg.subj(s).id '_' params.patname '_topo_' num2str(e) num2str(v) num2str(t) num2str(f) '.eps']);
	    print(h(v), '-depsc', '-r100', pat.figs.topo{e,v,t,f});
	  end
	end
      end
     
    end
    
  end
  
  eeg.subj(s) = setobj(eeg.subj(s), 'pat', pat);
end

% if params.across_subj
%   pat = getobj(eeg, 'pat', params.patname);
%   pattern = loadPat(pat.file);
  
%   if params.topo
%     h = topoplot(pattern(e,:,t,f), params);
%     for v=1:length(h)
%       pat.figs.topo{e,v,t,f} = fullfile(resDir, 'topo', [eeg.subj(s).id '_' params.patname '_topo_' num2str(e) num2str(v) num2str(t) num2str(f) '.eps']);
%       print(h(v), '-depsc', '-r100', pat.figs.topo{e,v,t,f});
%     end
%   end
  
% end
% eeg = setobj(eeg, 'pat', pat);

save(fullfile(eeg.resDir, 'eeg.mat'), 'eeg');